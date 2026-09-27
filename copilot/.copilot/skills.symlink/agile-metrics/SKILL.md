---
name: agile-metrics
description: Métriques agiles (vélocité, débit, cycle time, lead time, WIP, prévisibilité, carry-over, qualité), Definition of Ready/Done, points de vigilance et prévision probabiliste à partir de Jira. À utiliser pour un bilan de sprint, une rétro, une prévision ou la revue d'une story.
---
# Definition of Ready (story prête à entrer en sprint)
- Valeur et utilisateur explicites ; AC en Given/When/Then testables.
- Aucune question PO `[bloquante]` ouverte.
- Estimée par l'équipe, ≤ taille max d'une story (défaut 5 j) ; sinon découpée.
- Dépendances identifiées et levées ou planifiées ; maquettes disponibles si front.
- Données et environnement de test connus ; impacts sécurité/RGPD identifiés.

# Definition of Done (défaut, à adapter dans AGENTS.md)
Code revu et mergé, `verify:affected` vert, tests unitaires + intégration/E2E des AC, doc à jour, observabilité en place (logs, métriques, alarmes si prod), démontré au PO, déployable (feature flag si incomplet), aucune dette non tracée.

# Métriques
| Métrique | Calcul (Jira) | Lecture |
|---|---|---|
| **Vélocité** | somme des estimations (points ou jours) des tickets *Done* dans le sprint | tendance sur 6 sprints ; forte variance = prévision fragile |
| **Engagement vs réalisé** (say/do) | réalisé ÷ engagé au démarrage du sprint | cible 80–100 % ; < 70 % répété = surengagement ou imprévus |
| **Débit** (throughput) | nombre de tickets *Done* par sprint ou par semaine | plus robuste que la vélocité pour prévoir |
| **Cycle time** | date *Done* − date du premier passage *In Progress* (changelog) | médiane et 85e percentile ; la dispersion compte plus que la moyenne |
| **Lead time** | date *Done* − date de création | ce que perçoit le PO/métier |
| **WIP** | tickets *In Progress* simultanés | WIP > nombre de devs = multitâche ; corrélé au cycle time |
| **Temps bloqué** | durée en statut *Blocked* ou flag | révèle les dépendances externes |
| **Carry-over** | tickets engagés non terminés reportés au sprint suivant | > 20 % = découpage ou engagement à revoir |
| **Scope change** | tickets ajoutés/retirés après le démarrage | instabilité des priorités |
| **Précision d'estimation** | réalisé ÷ estimé par ticket (jours) | biais moyen (> 1 = sous-estimation) ; alimente la calibration |
| **Bugs échappés** | bugs créés en prod liés à des tickets livrés | qualité de la DoD |
| **Ratio bugs / features** | tickets bug ÷ total livré | dette ou instabilité |
| **Âge des tickets en cours** | aujourd'hui − début *In Progress* | ticket > 85e percentile du cycle time = à traiter au daily |

# Signaux d'alerte
- Cycle time p85 en hausse sur 3 sprints ; WIP durablement > nombre de devs.
- Say/do < 70 % deux sprints de suite ; carry-over > 20 %.
- Une story > 50 % de la capacité d'un sprint ; story sans AC testables en sprint.
- Dépendance externe sans date d'engagement ; question PO bloquante non résolue au démarrage.
- Connaissance concentrée sur une personne (bus factor 1) ; tâches de test systématiquement en fin de sprint.
- Biais d'estimation constant (> 1,3 ou < 0,7).

# Prévision
- Monte-Carlo sur le débit historique (≥ 6 sprints) : tirer au hasard des débits passés pour simuler N itérations, donner les dates aux percentiles 50 / 85.
- À défaut : fourchette = (vélocité min, médiane, max) des 6 derniers sprints appliquée au reste à faire.
- Jamais une date unique ; toujours la confiance associée.

# Rétro
3 sujets maximum, chacun : constat chiffré → cause probable → action concrète (qui, quoi, pour quand) → métrique qui dira si l'action a marché.

# Éthique
Métriques d'équipe, jamais individuelles ; pas de classement ; toujours l'échantillon et les exclusions.
