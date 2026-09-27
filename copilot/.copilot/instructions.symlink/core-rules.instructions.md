---
description: "Règles transverses de l'escouade d'agents (tous projets), chargées à chaque requête"
applyTo: '**'
---
# Règles transverses

## Exécution
- Toujours passer par un script npm (`npm run <script>`). Jamais `nx`/`npx nx` en direct (bloqué par hook).
- Script manquant → le proposer dans `package.json`, ne pas contourner.
- Contexte projet : lire `AGENTS.md` à la racine du repo s'il existe (scripts, libs, conventions locales). Il prime sur ces règles.

## Code
- Architecture hexagonale : `domain` ← `application` ← `infrastructure`. Détails : skill `hexagonal-architecture`.
- Fichiers kebab-case + suffixe métier (`.adapter.ts`, `.port.ts`, `.use-case.ts`, `.factory.ts`, `.manager.ts`…). Classes/interfaces PascalCase **sans préfixe `I`**. Variables camelCase.
- Front : `data-testid` stable sur tout élément interactif ou assertable. WCAG 2.2 AA.

## Espace de travail d'une tâche
- Dossier `.agents-work/<task-id>/` (ignoré par git) : `plan.md`, `lot-<n>.md`, `findings.md`, `status.md`, `commit-<n>.txt`.
- Lire ces fichiers plutôt que demander le contexte. Écrire uniquement dans les fichiers qui te sont attribués.

## Contrat de retour (tous les sous-agents)
Répondre UNIQUEMENT dans ce format, sans préambule :
```
STATUS: ok | blocked | needs-review
FILES: <chemins modifiés/créés, ou "none">
FINDINGS:
- [critical|high|medium|low] fichier:ligne — constat → action
BLOCKERS: <ou "none">
QUESTIONS: <questions pour l'utilisateur, ou "none">
```
- Ne jamais s'adresser à l'utilisateur : seul l'Orchestrator lui parle.
- Ne jamais modifier un fichier hors du périmètre attribué ; si nécessaire → `STATUS: blocked`.

## Git
- Commit/push/rebase/reset : uniquement par l'agent Git, après accord de l'utilisateur (le hook demande confirmation).
- Commits : anglais, Conventional Commits, body « problème → solution », aucun `Co-authored-by`.
