---
name: testing-playwright
description: Conventions E2E Playwright basées sur data-testid. À utiliser pour écrire ou corriger des tests Playwright.
---
- `page.getByTestId()` en priorité (`testIdAttribute: 'data-testid'`), `getByRole` pour valider l'a11y. Pas de sélecteur CSS fragile.
- Assertions web-first (`await expect(locator).toBeVisible()`), jamais `waitForTimeout`.
- `page.route()` pour isoler le back si pertinent ; auth via `storageState` ; fixtures pour l'état.
- Projets desktop + mobile sur les parcours critiques. Option a11y : `@axe-core/playwright`.
