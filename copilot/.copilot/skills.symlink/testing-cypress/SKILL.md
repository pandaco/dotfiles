---
name: testing-cypress
description: Conventions E2E Cypress basées sur data-testid. À utiliser pour écrire ou corriger des tests Cypress.
---
- Sélecteurs uniquement `[data-testid="..."]` (commande `cy.getByTestId` si présente). Jamais classes CSS ni textes.
- Aucun `cy.wait(<ms>)` : `cy.intercept` + alias, ou assertions.
- Données via fixtures/seed API ; tests indépendants et rejouables ; un parcours par `it`.
- Viewport mobile sur les parcours critiques. Option a11y : `cypress-axe`.
