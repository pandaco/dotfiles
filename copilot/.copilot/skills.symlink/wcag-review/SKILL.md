---
name: wcag-review
description: Checklist accessibilité WCAG 2.2 AA pour composants Angular (ARIA, clavier, focus, contrastes). À utiliser pour auditer ou corriger l'accessibilité d'un composant.
---
- HTML sémantique d'abord (`button`, `a`, `nav`, `main`, `label for`) ; ARIA seulement si nécessaire.
- Clavier : tout contrôle atteignable et activable ; ordre logique ; focus visible (2.4.7, 2.4.11) ; pas de piège.
- Modales : `role="dialog"`, `aria-modal="true"`, `aria-labelledby`, focus trap, retour du focus au déclencheur, `Escape` ferme.
- Formulaires : label associé, erreurs reliées par `aria-describedby`, `aria-invalid`, annonce `aria-live="polite"`, `autocomplete` pertinent.
- Contrastes : 4.5:1 texte, 3:1 gros texte et composants UI. Information jamais portée par la couleur seule.
- Images : `alt` pertinent, `alt=""` si décoratives. Bouton-icône : `aria-label`.
- Dynamique : régions live, `aria-busy` pendant chargement, titre de page mis à jour à la navigation.
- `prefers-reduced-motion` respecté. Cibles ≥ 24×24 px (2.5.8). Pas de glisser obligatoire (2.5.7).
- Vérif automatique possible : `@axe-core/playwright` dans les E2E.
