---
name: requirements-analysis
description: Grille d'analyse et de challenge d'un besoin (ticket Jira, user story) — reformulation, critères d'acceptation Given/When/Then, subtilités, questions au Product Owner. À utiliser pour analyser ou challenger une spec.
---
# Qualité d'une story (INVEST)
Indépendante, Négociable, porteuse de Valeur, Estimable, Small (≤ 1 sprint), Testable. Une story qui échoue à un critère → le signaler et proposer un découpage.

# Critères d'acceptation
- Format `ACn — Given <contexte> / When <action> / Then <résultat observable>`.
- Un AC = un comportement vérifiable (test automatisable). Refuser « rapide », « intuitif », « comme d'habitude » sans seuil : proposer un seuil mesurable.
- Couvrir aussi le **chemin d'erreur** et les **droits** pour chaque AC nominal.

# Grille des subtilités (passer chaque ligne)
| Thème | Questions à se poser |
|---|---|
| Acteurs et droits | Qui peut faire l'action ? Rôles, propriété de l'objet, multi-tenant, admin, délégation |
| États et transitions | Quels statuts ? Transitions interdites ? Action déjà faite (idempotence) ? Annulation, retour arrière |
| Données existantes | Reprise/migration des données actuelles ? Valeurs nulles historiques ? Doublons ? |
| Rétrocompatibilité | Contrat d'API, événements Kafka, clients mobiles/anciennes versions, feature flag |
| Volumétrie et perf | Combien d'éléments ? Pagination, tri, recherche, export ? Temps de réponse attendu |
| Concurrence | Deux utilisateurs en même temps ? Double clic ? Traitements asynchrones en parallèle |
| Temps | Fuseaux horaires, dates limites, jours ouvrés, expiration, historique |
| Calculs | Arrondis, devise, TVA, unités, précision |
| Erreurs | Messages attendus, comportement en panne d'un service tiers, reprise |
| Notifications | Qui est prévenu, par quel canal, à quel moment, désinscription |
| i18n / a11y | Libellés traduits, formats locaux, accessibilité clavier/lecteur d'écran |
| RGPD / sécurité | Données personnelles, durée de conservation, droit à l'effacement, journalisation, audit |
| Observabilité | Quoi mesurer pour savoir que la fonctionnalité marche en production |
| Hors périmètre | Ce qui est explicitement exclu ; ce que le PO pourrait supposer inclus |

# Challenge
- Reformuler le **problème** sans la solution : la solution demandée est-elle la plus simple ?
- Proposer un **MVP** livrable en premier et les incréments suivants.
- Repérer la valeur la plus faible au coût le plus élevé (candidat à sortir du périmètre).
- Vérifier la cohérence avec l'epic et les tickets liés (doublon, dépendance, conflit).

# Questions au PO
- Priorité : `[bloquante]` > `[importante]` > `[confort]`.
- Formulation fermée ou à choix, avec l'option recommandée et l'hypothèse par défaut :
  `[bloquante] Une commande expédiée peut-elle être annulée ? (a) non (b) oui avec retour — hypothèse par défaut : (a)`.
- Regrouper par thème ; 10 questions maximum, les plus impactantes d'abord.

# Découpage d'une story trop grosse (pour le PO)
Principe : **tranches verticales**, chacune livrable, démontrable et testable seule, avec sa propre valeur. Jamais par couche technique.
| Technique (SPIDR+) | Exemple |
|---|---|
| **Chemins / parcours** | Paiement CB d'abord, virement ensuite |
| **Règles métier** | Annulation sans remboursement, puis avec remboursement partiel |
| **Données / variations** | Un seul type de produit, puis tous ; une devise, puis plusieurs |
| **Interfaces / canaux** | Web d'abord, export CSV ensuite, API partenaire après |
| **Opérations** | Consulter → créer → modifier → supprimer |
| **Nominal puis erreurs** | Cas nominal + erreurs bloquantes ; erreurs rares et reprises ensuite |
| **Performance / volume** | Fonctionnel sur petit volume, optimisation grand volume ensuite |
| **Spike** | Étude time-boxée (≤ 1 j) quand une inconnue empêche d'estimer |
Contrôles : chaque story respecte INVEST, a des AC testables par le PO, est ≤ seuil de taille ; l'ensemble couvre tous les AC d'origine ; la première story (MVP) apporte déjà de la valeur.

Format de `story-split.md` :
```markdown
# Découpage proposé — <JIRA-KEY> (<total> j → <n> stories)
| # | Story (En tant que…, je veux…, afin de…) | Valeur | AC | Tâches | Estimation | Dépend de | Démo PO |
## Couverture des AC d'origine
| AC d'origine | Story |
## Hors périmètre de toutes les stories
```
