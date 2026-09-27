---
name: estimation
description: Règles d'estimation en jours et de découpage technique et logique en tâches d'une journée, estimation indépendante à 3 (planning poker), consolidation et format du livrable. À utiliser pour découper, estimer ou relire une estimation.
---
# Unité
**1 tâche = 1 jour de travail** d'un développeur de l'équipe, incluant : le code, ses tests unitaires, la vérification locale (`verify:affected`) et la prise en compte de la revue de code.
- Tâche estimée > 1 j → la redécouper. Tâche < ½ j → la fusionner avec la tâche logiquement voisine (même couche, même composant).
- Les tests d'intégration et E2E sont des **tâches à part** (type `test`).
- Hors estimation (listés à part) : recette PO, déploiement en production, réunions, attente de réponses PO.

# Découpage technique et logique
- **Logique** : chaque tâche produit un incrément vérifiable et mergeable (build vert), dans l'ordre des dépendances.
- **Technique** : une tâche reste dans une couche ou une lib (domaine, application, infrastructure/adapter, API, front, données, infra AWS, tests).
- Ordre type : contrats (ports, DTO, schéma) → migrations/données → domaine + use cases → adapters/API → front → tests d'intégration/E2E → doc.
- Chaque tâche indique : AC couverts, dépendances, fichiers/libs touchés, définition de terminé.
- Rendre le parallélisme visible : tâches sans dépendance commune = réalisables en même temps par 3 développeurs.

# Estimation indépendante à 3
- Chaque Implementer estime **seul**, sans voir les autres, chaque tâche en jours avec l'échelle `0.5, 1, 1.5, 2, 3, 5` et une justification d'une ligne pour toute valeur ≠ 1.
- Il signale : tâche mal découpée, dépendance oubliée, risque technique, hypothèse prise.
- Il estime aussi les **tâches de test** et propose les tests manquants (tâche `test` supplémentaire si nécessaire).

# Consolidation
- Valeur retenue = **médiane** des 3.
- Écart fort (max ≥ 2 × min) ou médiane > 1 → tâche à redécouper ou à clarifier (une seule itération, puis on garde la médiane et on note le risque).
- Fourchette : somme des minimums – somme des maximums.
- Confiance : **haute** (écarts faibles, aucune question bloquante), **moyenne** (quelques écarts ou questions importantes), **basse** (questions bloquantes ouvertes, technologie inconnue).
- Marge de risque explicite (en jours, justifiée) plutôt que multiplier tout par un coefficient.
- Durée calendaire à 3 développeurs = chemin critique des dépendances (pas total / 3).

# Format de `estimation.md`
```markdown
# Estimation <JIRA-KEY> — <titre>
Total : <N> j (réalisation <X> j · tests <Y> j) · Fourchette : <min>–<max> j · Confiance : haute|moyenne|basse
Durée calendaire à 3 devs : <D> j (chemin critique : T1 → T3 → T7)
Marge de risque proposée : <R> j — <raison>

## Hypothèses
- ...
## Questions PO ouvertes et impact
| Question | Impact si réponse défavorable |
## Tâches
| # | Tâche | Type | Couche / lib | Dépend de | AC | I1 | I2 | I3 | Retenu |
|---|---|---|---|---|---|---|---|---|---|
| T1 | Port OrderRepository + DTO annulation | dev | domain | - | AC1 | 1 | 1 | 0.5 | 1 |
## À redécouper / clarifier
- T4 : I2 = 3 j (« gestion du remboursement partiel non spécifiée ») → question PO Q3
## Risques
## Hors estimation
- Recette PO, déploiement, ...
```

# Export Jira (après accord)
Chaque tâche peut devenir une sous-tâche Jira : résumé = `T<n> — <tâche>`, description = couche, dépendances, AC, définition de terminé, estimation d'origine `1d`. Création uniquement après accord explicite de l'utilisateur.
