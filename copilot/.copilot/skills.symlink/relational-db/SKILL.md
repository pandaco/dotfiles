---
name: relational-db
description: Expertise SQL relationnelle (PostgreSQL en priorité, notes MySQL) et TypeORM — lecture de plans d'exécution, index, requêtes performantes, fonctions/triggers/vues côté base, transactions, migrations sans interruption. À utiliser pour optimiser, modéliser, expliquer ou relire du SQL.
---
# 1. Mesurer
- Top requêtes : `pg_stat_statements` trié par `total_exec_time` puis `mean_exec_time` ; MySQL : `performance_schema.events_statements_summary_by_digest`.
- `EXPLAIN (ANALYZE, BUFFERS, VERBOSE)` sur une base de dev avec une **volumétrie réaliste** (un plan sur 100 lignes ne prouve rien). `ANALYZE` exécute la requête : jamais sur une requête d'écriture.
- Lire le plan de bas en haut. Signaux :
  - `Seq Scan` sur une grosse table avec filtre sélectif → index manquant ou prédicat non SARGable.
  - `rows` estimé ≠ réel (×10) → `ANALYZE`, `CREATE STATISTICS` (colonnes corrélées), `default_statistics_target` sur la colonne.
  - `Rows Removed by Filter` élevé → l'index ne couvre pas le filtre.
  - `Nested Loop` avec `loops` très élevé → jointure mal indexée ou mauvaise estimation.
  - `Sort Method: external merge` / `Hash Batches > 1` → `work_mem` ou index qui fournit l'ordre.
  - `Heap Fetches` élevé sur `Index Only Scan` → vacuum/visibility map.
- Index inutilisés : `pg_stat_user_indexes.idx_scan = 0` (sur une période représentative). Doublons : même préfixe de colonnes.

# 2. Index
- B-tree composite : colonnes d'**égalité** d'abord, puis la colonne de **tri**, puis la colonne de **plage** (règle ESR). Préfixe gauche : `(a, b)` sert `a` et `a, b`, pas `b` seul.
- **Covering** : `INCLUDE (col)` pour un index-only scan (PostgreSQL ≥ 11).
- **Partiel** : `WHERE deleted_at IS NULL`, `WHERE status = 'pending'` — petit, rapide, exige le même prédicat dans la requête.
- **Expression** : `lower(email)`, `(payload->>'type')` — la requête doit utiliser exactement l'expression.
- **GIN** : `jsonb` (`jsonb_path_ops` pour `@>`), tableaux, full-text (`tsvector`). **pg_trgm** (GIN) pour `ILIKE '%x%'`. **BRIN** pour tables append-only triées par date. **GiST** pour plages/géo/exclusion.
- **Clés étrangères** : PostgreSQL ne les indexe pas automatiquement → index sur la colonne FK (jointures, `ON DELETE`).
- Unicité métier = index `UNIQUE` (éventuellement partiel), pas un contrôle applicatif seul.
- Chaque index ralentit les écritures et occupe de la place : le justifier par une requête.
- Création en production : `CREATE INDEX CONCURRENTLY` (hors transaction ; migration TypeORM avec `transaction = false`), `DROP INDEX CONCURRENTLY`.

# 3. Requêtes performantes
- Prédicats **SARGable** : pas de fonction ni de cast implicite sur la colonne indexée (`created_at >= $1` plutôt que `date(created_at) = $1`).
- Pagination **keyset** (`WHERE (created_at, id) < ($1, $2) ORDER BY created_at DESC, id DESC LIMIT 50`) plutôt qu'`OFFSET` sur de gros volumes.
- Colonnes explicites, jamais `SELECT *` sur les chemins chauds.
- `EXISTS` pour tester une relation ; `NOT EXISTS` plutôt que `NOT IN` (piège des `NULL`).
- Top-N par groupe : `LATERAL (… ORDER BY … LIMIT n)` ou `DISTINCT ON`. Classements/cumuls : fonctions de fenêtre.
- CTE : inlinées depuis PostgreSQL 12 sauf `MATERIALIZED` ; l'utiliser volontairement pour forcer ou éviter la matérialisation.
- Écritures en lot : `INSERT … SELECT unnest($1::int[], $2::text[])`, `INSERT … ON CONFLICT … DO UPDATE` (upsert atomique), `COPY` pour l'import massif, `UPDATE … FROM (VALUES …)`.
- `count(*)` exact sur très grosse table : compteur maintenu ou estimation (`pg_class.reltuples`) si l'exactitude n'est pas requise.
- N+1 : une requête avec jointure ou `WHERE id = ANY($1)` par lot.

# 4. Fonctions, triggers, vues côté base
- À utiliser pour : intégrité (`CHECK`, contraintes d'exclusion, colonnes `GENERATED ALWAYS AS … STORED`), triggers techniques (`updated_at`, audit), traitements set-based qui évitent des allers-retours, upserts/compteurs atomiques, files de travail (`SELECT … FOR UPDATE SKIP LOCKED`), agrégats coûteux en **vue matérialisée** (`REFRESH MATERIALIZED VIEW CONCURRENTLY` exige un index unique).
- À éviter pour : règles métier qui appartiennent au domaine, logique qui doit être testée unitairement sans base, appels réseau.
- Fonctions SQL simples `LANGUAGE sql` (inlinables) avant `plpgsql`. Déclarer la volatilité juste (`IMMUTABLE` / `STABLE` / `VOLATILE`), `PARALLEL SAFE` si vrai. `SECURITY DEFINER` seulement avec `SET search_path = pg_catalog, public` et droits `EXECUTE` restreints.
- Triggers : coût à chaque ligne écrite ; préférer `FOR EACH STATEMENT` + tables de transition pour les traitements en masse.
- Toujours en migration versionnée + test d'intégration ; appel via un adapter (`infrastructure`).

# 5. Schéma et types
- `timestamptz` (jamais `timestamp` sans fuseau), `numeric(p,s)` pour l'argent, `bigint GENERATED ALWAYS AS IDENTITY` ou UUID v7 (ordonné, meilleur pour les index que v4), `text` + `CHECK` plutôt que `varchar(n)` arbitraire, enum PostgreSQL seulement si la liste est stable.
- `NOT NULL` par défaut, FK déclarées, `CHECK` pour les invariants simples.
- `jsonb` pour des attributs réellement variables ; une donnée filtrée ou jointe souvent mérite une colonne.
- Normaliser d'abord, dénormaliser de façon ciblée et mesurée (colonne calculée, vue matérialisée).
- Partitionnement (range par date, list par tenant) pour les tables très volumineuses avec purge par période.

# 6. Transactions et concurrence
- Transactions courtes ; jamais d'appel réseau à l'intérieur.
- Isolation `READ COMMITTED` par défaut ; `REPEATABLE READ`/`SERIALIZABLE` avec retry si nécessaire.
- Verrouillage optimiste (`@VersionColumn`) pour les éditions concurrentes ; `FOR UPDATE` ciblé sinon ; ordre de verrouillage constant contre les deadlocks ; advisory locks pour les tâches singleton.

# 7. Migrations sans interruption
- `SET lock_timeout = '5s'` et `statement_timeout` dans les migrations risquées.
- Ajouter une colonne : nullable ou avec défaut **constant** (instantané depuis PostgreSQL 11) ; backfill par lots ; `NOT NULL` via `CHECK (col IS NOT NULL) NOT VALID` puis `VALIDATE CONSTRAINT`.
- FK sur grosse table : `NOT VALID` puis `VALIDATE`.
- Renommer/supprimer : expand → migrer le code → contract, sur plusieurs déploiements.
- Jamais modifier une migration appliquée ; `synchronize: false` hors local.

# 8. TypeORM
- Paramètres nommés dans `createQueryBuilder` (`where('o.status = :status', { status })`), jamais d'interpolation.
- `select` explicite ; `relations` multiples → explosion cartésienne : `relationLoadStrategy: 'query'` ou requêtes séparées.
- `skip/take` avec jointures → sous-requête sur les IDs ; préférer keyset.
- Agrégats : `getRawMany()` typé ; gros volumes : `.stream()`.
- Index : `@Index()` sur l'entité **et** migration générée relue (vérifier `CONCURRENTLY` à la main si nécessaire).
- Transactions : `dataSource.transaction(async (em) => …)`, repositories issus de `em`.

# 9. Exploitation
- Pool de connexions dimensionné (Lambda : RDS Proxy ; PgBouncer en mode transaction → attention aux prepared statements et `SET` de session).
- Autovacuum surveillé sur les tables très écrites (bloat, `n_dead_tup`), `fillfactor` réduit pour les mises à jour HOT fréquentes.
- `statement_timeout` par rôle applicatif.

# MySQL (différences clés)
InnoDB : la clé primaire est l'index cluster (PK courte et croissante), les index secondaires contiennent la PK ; pas d'index partiel ; index fonctionnels depuis 8.0.13 ; `EXPLAIN ANALYZE` depuis 8.0.18 ; DDL en ligne (`ALGORITHM=INPLACE, LOCK=NONE`) ou outils type gh-ost pour les grosses tables.
