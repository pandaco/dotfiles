---
name: owasp-review
description: Checklist d'audit sécurité OWASP pour NestJS, TypeORM, Angular, Kafka et AWS Lambda. À utiliser pour relire un diff sous l'angle sécurité.
---
- **Injection** : TypeORM paramétré (`where('x = :x', { x })`), jamais de concaténation dans `query()`/`createQueryBuilder`. Pas d'`eval`/`new Function`. Arguments shell échappés.
- **Validation** : DTO `class-validator`, `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true })`. Limites de taille (body, pagination).
- **AuthN** : JWT (algo fixé, `exp`, `aud`, `iss` vérifiés), refresh tokens rotatifs, pas de secret par défaut.
- **AuthZ** : guard sur chaque route ; contrôle d'accès **à l'objet** (IDOR) ; rôles jamais issus du client.
- **XSS Angular** : pas de `bypassSecurityTrust*`, pas d'`innerHTML` non maîtrisé.
- **Données sensibles** : aucun secret en dur ; pas de PII/tokens dans les logs ; erreurs non verbeuses côté client.
- **Config HTTP** : CORS restrictif, `helmet`, rate limiting, cookies `HttpOnly`/`Secure`/`SameSite`.
- **Kafka / Lambda** : validation de schéma des messages entrants, idempotence, IAM au moindre privilège, pas de secrets en variables d'env en clair (Secrets Manager/SSM).
- **SSRF** : URLs sortantes en liste blanche.
- **Dépendances** : `npm audit --omit=dev`, signaler high/critical.
Sévérités : critical (exploitable à distance sans auth), high, medium, low.
