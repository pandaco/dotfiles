---
name: hexagonal-architecture
description: Règles d'architecture hexagonale, Clean Code et conventions de nommage pour NestJS/Angular en monorepo Nx. À utiliser pour concevoir un plan, créer des fichiers ou relire une structure.
---
# Couches
- `domain/` : entités, value objects, erreurs métier, **ports** (interfaces). Aucune dépendance framework (ni Angular, ni NestJS, ni TypeORM, ni Kafka).
- `application/` : use cases qui orchestrent les ports. Dépend du domaine uniquement.
- `infrastructure/` : **adapters** (TypeORM, HTTP, Kafka, AWS), controllers NestJS, mappers, config.
- Sens des dépendances : infrastructure → application → domain. Jamais l'inverse.
- Injection : tokens NestJS (`export const ORDER_REPOSITORY = Symbol('ORDER_REPOSITORY')`) ou `InjectionToken` Angular.
- Frontières Nx : `tags` dans `project.json` + règle `@nx/enforce-module-boundaries` (ex. `type:domain` ne dépend que de `type:domain`).

# Nommage
| Élément | Fichier | Classe |
|---|---|---|
| Port | `order-repository.port.ts` | `OrderRepository` (interface, **pas de `I`**) |
| Adapter | `typeorm-order-repository.adapter.ts` | `TypeOrmOrderRepository` |
| Use case | `create-order.use-case.ts` | `CreateOrderUseCase` |
| Factory | `order.factory.ts` | `OrderFactory` |
| Manager | `session.manager.ts` | `SessionManager` |
| Mapper | `order.mapper.ts` | `OrderMapper` |
| DTO | `create-order.dto.ts` | `CreateOrderDto` |
| Entité | `order.entity.ts` | `Order` |
Variables/fonctions camelCase. Constantes de token SCREAMING_SNAKE_CASE.

# Clean Code
SRP, fonctions courtes, early return, pas de magic numbers, erreurs métier typées (`OrderNotFoundError`), pas de logique métier dans controllers/adapters. Nommer le pattern utilisé (Factory, Strategy, Adapter, Repository, Specification) quand il y en a un.
