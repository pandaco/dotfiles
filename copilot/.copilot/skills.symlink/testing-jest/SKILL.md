---
name: testing-jest
description: Conventions d'écriture de tests Jest pour NestJS et Angular (zoneless, signals). À utiliser pour écrire ou corriger des tests Jest.
---
- `*.spec.ts` à côté du code. AAA, un comportement par `it`, noms anglais (`should reject order when stock is empty`).
- NestJS : `Test.createTestingModule`, ports mockés via tokens (`{ provide: ORDER_REPOSITORY, useValue: repo }`), `jest.Mocked<OrderRepository>`. Aucun réseau/BDD réel en unitaire.
- Angular : `TestBed` + `provideZonelessChangeDetection()` (ou `provideExperimentalZonelessChangeDetection()` selon version) ; `fixture.componentRef.setInput()` pour les `input()` ; `await fixture.whenStable()`.
- Couvrir : nominal, limites, erreurs. Pas de snapshot sauf demande. `jest.useFakeTimers()` pour le temps.
