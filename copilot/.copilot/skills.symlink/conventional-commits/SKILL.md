---
name: conventional-commits
description: Règles de rédaction des commits (Conventional Commits, anglais, body problème→solution, sans co-auteur) et de nettoyage d'historique. À utiliser pour proposer ou relire des commits.
---
# Format
```
<type>(<scope>): <subject>

<Problem: what was wrong or missing, and why it matters.>

<Solution: how this commit fixes it.>

Refs: <JIRA-KEY>   (si ticket)
```
- Types : feat, fix, refactor, perf, test, docs, chore, ci, build, style, revert. `!` ou `BREAKING CHANGE:` si rupture.
- Scope = app/lib Nx. Sujet : anglais, impératif, minuscule, ≤ 72 caractères, sans point final.
- **Body obligatoire** (problème puis solution), lignes ≤ 72 caractères.
- **Jamais** de `Co-authored-by`, `Signed-off-by` d'outil, ni mention d'IA.
- Un commit = un changement cohérent qui build.

# Commande
```bash
git commit -m "feat(api): add order cancellation" \
  -m "Paid orders could not be cancelled, so support edited the database by hand." \
  -m "Add CancelOrderUseCase, POST /orders/:id/cancel and the refund event." \
  -m "Refs: ABC-123"
```
Chaque `-m` devient un paragraphe (git insère une ligne vide entre eux) : le 1er est le sujet, les suivants le body. Message généré par le shell (`$(cat …)`, heredoc) interdit : non vérifiable par le garde-fou.

# Historique
- Commits locaux non poussés quasi identiques (fixup, WIP, « typo ») → squash. Proposer le plan `pick`/`fixup` ; exécuter seulement après accord.
- Ne jamais réécrire un historique déjà poussé sans accord explicite dédié.
