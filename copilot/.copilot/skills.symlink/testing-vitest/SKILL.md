---
name: testing-vitest
description: Conventions d'écriture de tests Vitest pour Angular zoneless et libs TypeScript. À utiliser pour écrire ou corriger des tests Vitest.
---
- `*.spec.ts` à côté du code ; `describe/it/expect/vi` importés de `vitest`.
- Mocks : `vi.fn()`, `vi.spyOn()`, `vi.mocked()` ; temps : `vi.useFakeTimers()`.
- Angular : `TestBed` zoneless, `setInput()` pour les signals, `await fixture.whenStable()` plutôt que `detectChanges()` en boucle.
- AAA, un comportement par test, noms anglais. Nominal, limites, erreurs.
