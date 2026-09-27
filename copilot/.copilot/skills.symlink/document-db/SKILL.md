---
name: document-db
description: Expertise bases orientées documents et clé-valeur (MongoDB/Mongoose, DynamoDB) — modélisation par access patterns, index, explain, agrégations, requêtes et écritures efficaces, coûts. À utiliser pour modéliser, optimiser, expliquer ou relire du NoSQL.
---
# Principe
Modéliser à partir de la **liste des access patterns** (requête, filtre, tri, fréquence, volumétrie, latence attendue), pas à partir des entités. Écrire cette liste dans le plan avant tout schéma.

# MongoDB
## Modélisation
- **Embarquer** ce qui est lu ensemble et borné (adresses d'un client). **Référencer** ce qui croît sans limite ou est partagé (commandes d'un client). Limite : 16 Mo par document ; un tableau non borné est un anti-pattern.
- Patterns : *subset* (les N derniers éléments embarqués, le reste référencé), *extended reference* (copie des champs lus souvent), *computed* (totaux maintenus à l'écriture), *bucket* (séries temporelles par fenêtre ; ou collections time series natives), *outlier*, *schema versioning* (`schemaVersion`).
- Validation côté serveur : `$jsonSchema` sur la collection, en plus du schéma Mongoose.

## Index
- Règle **ESR** : champs d'**E**galité, puis de **S**ort, puis de **R**ange dans l'index composé.
- Multikey (tableaux) : un seul champ tableau par index composé. Index partiels (`partialFilterExpression`), `unique`, **TTL** pour l'expiration, index texte/Atlas Search pour la recherche. Wildcard seulement en dernier recours.
- **Requête couverte** : projection limitée aux champs de l'index (et `_id: 0`).
- `explain('executionStats')` : viser `IXSCAN`, `totalDocsExamined` ≈ `nReturned`, pas d'étape `SORT` en mémoire, `totalKeysExamined` proche de `nReturned`. `COLLSCAN` sur une collection volumineuse = défaut.
- Index inutilisés : `$indexStats`. Chaque index coûte en écriture et en RAM (working set).

## Requêtes et agrégations
- Pipeline : `$match` et `$sort` **en premier** (utilisent les index), `$project`/`$unset` tôt, `$limit` avant les étapes coûteuses. `$lookup` : index sur le champ étranger, sous-pipeline filtré ; fréquent = signe qu'il fallait embarquer. `allowDiskUse` seulement si justifié.
- Pagination par plage (`_id`/champ indexé `> dernier`) plutôt que `skip`.
- Écritures : `bulkWrite` ordonné ou non, opérateurs atomiques (`$inc`, `$push` avec `$slice`, `$setOnInsert` pour l'upsert), `findOneAndUpdate` pour lire-modifier atomiquement. Transactions multi-documents seulement si l'invariant l'exige.
- Mongoose : `.lean()` en lecture, `.select()` explicite, `populate` = requêtes supplémentaires (N+1 potentiel), `strictQuery`, index déclarés dans le schéma **et** `autoIndex: false` en production (index créés par migration).
- Write concern `majority` pour les données critiques ; read preference secondaire seulement si la lecture tolère le retard.
- Sharding : clé à forte cardinalité, bien répartie, non monotone (sinon hot shard), présente dans les requêtes principales.

# DynamoDB
## Modélisation
- Lister les access patterns, puis concevoir **PK/SK** pour que chacun soit un `GetItem` ou un `Query`. Jamais de `Scan` sur un chemin applicatif.
- PK à **forte cardinalité** et accès uniformes (sinon partition chaude ; *write sharding* avec suffixe si nécessaire). SK pour les hiérarchies et plages (`begins_with`, `between`) : `ORDER#2026-09-27#<id>`.
- Single-table : efficace quand les entités sont lues ensemble ; multi-tables plus lisible sinon. Choisir explicitement.
- Relations 1-N : même PK, SK préfixée ; N-N : *adjacency list* + GSI inversé.

## Index
- **GSI** : projection minimale (`KEYS_ONLY`/`INCLUDE`), lecture éventuellement cohérente, chaque écriture est répliquée (coût). **GSI creux** (attribut présent seulement sur les items concernés) pour les filtres rares (`pending`).
- **LSI** : uniquement à la création de la table, limite de 10 Go par valeur de PK.

## Requêtes et écritures
- `ProjectionExpression` pour réduire la taille lue ; `FilterExpression` ne réduit **pas** la capacité consommée (filtre après lecture).
- Pagination avec `LastEvaluatedKey` ; `Limit` s'applique avant le filtre.
- `BatchGetItem`/`BatchWriteItem` avec relance des `UnprocessedItems`/`UnprocessedKeys` (backoff exponentiel).
- `TransactWriteItems` pour les invariants multi-items (coût ×2, 100 items max).
- **Écritures conditionnelles** (`attribute_not_exists`, compteur de version) pour l'idempotence et le verrouillage optimiste.
- TTL pour la purge, Streams pour les projections/événements.
- Item ≤ 400 Ko : gros contenus dans S3, référence dans l'item.
- Capacité : on-demand pour trafic imprévisible, provisionné + auto scaling pour trafic stable ; mesurer `ConsumedCapacity` (`ReturnConsumedCapacity: 'INDEXES'`).

# Fonctions côté base
- MongoDB : pipelines d'agrégation, `$merge`/`$out` pour les vues matérialisées, change streams pour réagir aux écritures. Pas de logique métier dans des scripts serveur.
- DynamoDB : pas de fonctions intégrées ; Streams + Lambda pour les projections, expressions de mise à jour atomiques (`ADD`, `SET if_not_exists`).
