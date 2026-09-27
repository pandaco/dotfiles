---
name: task-workspace
description: Format des fichiers de travail d'une tâche multi-agents dans .agents-work/<task-id>/ (analysis.md, breakdown.md, estimation.md, plan.md, lot-n.md, findings.md, status.md, commit-n.txt). À utiliser pour écrire ou lire un plan, un compte rendu de lot ou des constats.
---
# Arborescence
```
.agents-work/scrum/<date>/   # Scrum-Master : data.json, report.md (bilans de sprint)
.agents-work/<task-id>/
  analysis.md    # Business-Analyst : besoin, AC, challenge, subtilités, questions PO
  breakdown.md   # Architecture : tâches d'1 jour (mode estimation)
  estimate-<n>.md# Implementer n : estimation indépendante
  estimation.md  # Business-Analyst : consolidation (format du skill estimation)
  story-split.md # Business-Analyst : découpage en stories testables si trop gros
  vigilance.md   # Scrum-Master : DoR, tenue en sprint, vigilance, métriques à suivre
  plan.md        # Architecture (validé par Advisor + utilisateur)
  lot-<n>.md     # un par Implementer
  findings.md    # Security, Performance, A11y, QA
  status.md      # Orchestrator : étape courante, reprise
  commit-<n>.txt # Git : messages de commit
```

# plan.md
```markdown
# <task-id> — <titre>
Taille: S|M|L · Jira: <clé ou none>
## Besoin
<2-4 lignes> · Critères d'acceptation: <liste>
## Périmètre
Touché: <apps/libs> · Hors périmètre: <...>
## Contrats
<signatures ports / DTO / événements>
## Lots
| Lot | Fichiers (disjoints) | Dépend de | Vérification (script npm) |
|---|---|---|---|
| 0 | contrats + fichiers partagés | - | npm run lint:<projet> |
| 1 | ... | 0 | npm run test:<projet> |
## Patterns
- <pattern> — <justification>
## Tests
<unitaire / intégration / E2E, outil>
## Risques
- ...
```

# lot-<n>.md
```markdown
# Lot <n> — STATUS: ok|blocked
Fichiers: ...
Décisions / écarts au plan: ...
Vérification: `npm run ...` → pass|fail
## data-testid (si front)
| testid | élément |
```

# findings.md
Une section par agent (`## Security`, `## Performance`, `## A11y`, `## QA`), une ligne par constat :
`- [sévérité] fichier:ligne — constat → action — status: open|fixed|wontfix`

# status.md
```markdown
Étape: <n du workflow> · Vague: <k> · Sous-agents lancés: <x>/<budget>
Lots: 0 ok, 1 ok, 2 running, 3 pending
Advisor: plan APPROVED · final pending
Allers-retours Advisor: <agent>: <n>/2
```
