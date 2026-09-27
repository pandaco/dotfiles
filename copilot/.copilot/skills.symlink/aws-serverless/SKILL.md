---
name: aws-serverless
description: Checklist experte AWS pour CloudFormation, Serverless Framework et Lambda Node.js (IAM, données, événements Kafka/SQS, observabilité, coûts, déploiement sûr). À utiliser pour concevoir, modifier ou relire de l'IaC AWS.
---
# CloudFormation
- Ressources à état (RDS, DynamoDB, S3, KMS, Cognito, log groups importants) : `DeletionPolicy: Retain` **et** `UpdateReplacePolicy: Retain`.
- Repérer les changements qui **remplacent** une ressource (renommage de `LogicalId`, propriétés « Replacement: True » : `TableName`, `BucketName`, `DBInstanceIdentifier`, `KeySchema`…). Signaler en `critical` si perte de données possible.
- Pas de noms physiques codés en dur (bloque les remplacements, collisions entre stages) sauf besoin explicite.
- Paramètres sensibles : `AWS::SSM::Parameter::Value<String>` ou résolution dynamique `{{resolve:secretsmanager:…}}` ; jamais de secret en clair ni en `Default`.
- Exports cross-stack (`Fn::ImportValue`) : couplage fort, un export utilisé ne peut plus changer. Préférer SSM pour partager des valeurs.
- Limite de 500 ressources par stack : surveiller les services Serverless volumineux (découper en plusieurs services).
- Mises à jour : change set + relecture, `cfn-lint`, `cfn-guard` si règles. Tags de coût (`service`, `stage`, `owner`) sur toutes les ressources.

# Serverless Framework
- Identifier la version (`frameworkVersion`, package `serverless`) : v3 vs v4 (v4 : connexion/licence requises selon la taille de l'organisation). Ne pas changer de version majeure sans ADR.
- `provider.stage` / `--stage` paramétré ; configuration par stage via `params` ou fichiers dédiés, jamais de `if` sur le nom de stage dans le code.
- IAM : **un rôle par fonction** quand les droits diffèrent (`iam.role.statements` minimal au niveau provider, ou plugin de rôles par fonction). Pas de `Resource: '*'` ni d'`Action: 's3:*'` sauf justification.
- Variables d'environnement : `${ssm:…}` / Secrets Manager résolus au déploiement ou lus au runtime (avec cache), jamais de secret en dur ni dans le repo.
- Build : esbuild (natif v4 ou plugin), `external` pour le SDK AWS v3 fourni par le runtime si pertinent, bundle minimal, sourcemaps activés.
- Inspecter la CloudFormation réellement générée (`serverless package` → `.serverless/cloudformation-template-update-stack.json`) avant de conclure.
- Plugins : versions épinglées, vérifier la compatibilité avec la version du framework.

# Lambda (Node.js)
- Runtime Node.js LTS supporté, `architecture: arm64` sauf dépendance native incompatible.
- `timeout` < timeout de la source (API Gateway 29 s par défaut, visibilité SQS ≥ 6 × timeout Lambda). `memorySize` choisi par mesure (Power Tuning), pas par défaut.
- Handler fin : parsing/validation de l'événement → use case (hexagonal) → réponse. Clients SDK instanciés **hors** du handler.
- Idempotence obligatoire pour les sources « at least once » (SQS, Kafka, EventBridge) : clé d'idempotence + stockage (Powertools Idempotency / DynamoDB).
- Erreurs asynchrones : `onFailure` destination ou DLQ ; `maximumRetryAttempts` explicite.
- SQS : `functionResponseType: ReportBatchItemFailures` (échecs partiels), `batchSize`/`maximumBatchingWindow` réfléchis.
- Kafka (MSK ou Confluent via source auto-gérée) : secret d'authentification dans Secrets Manager, `startingPosition` explicite, `batchSize`, consumer group ID stable, gestion des échecs partiels et du poison message, désérialisation Avro/Schema Registry validée.
- Concurrence : `reservedConcurrency` pour protéger une ressource aval (RDS), provisioned concurrency seulement si la latence de cold start est un vrai problème.
- RDS : RDS Proxy ou pool limité, jamais une connexion par invocation sans limite.

# Sécurité
- IAM moindre privilège par fonction, conditions (`aws:SourceArn`, `aws:SourceAccount`) sur les permissions d'invocation.
- S3 : Block Public Access, chiffrement, `enforceSSL`. KMS clé gérée par le client pour les données sensibles.
- API Gateway : authorizer (JWT/Cognito/Lambda), throttling, validation de requête, WAF si exposé publiquement, CORS restrictif.
- VPC seulement si nécessaire (accès RDS privé) ; endpoints VPC plutôt que NAT pour S3/DynamoDB.
- Pas de PII ni de token dans les logs.

# Observabilité et coûts
- Logs JSON structurés (Powertools Logger), `logRetentionInDays` défini (jamais infini), corrélation (request id, trace id).
- Tracing X-Ray / Powertools Tracer sur les chemins critiques ; métriques métier (EMF).
- Alarmes CloudWatch : erreurs, throttles, durée p95 proche du timeout, âge du plus vieux message SQS, lag Kafka, DLQ non vide.
- Coûts : arm64, mémoire mesurée, rétention des logs, NAT Gateway (coût caché), requêtes provisionnées inutiles.

# Déploiement
- Jamais depuis un agent. Proposer : script npm de déploiement par stage, change set à relire, ordre de déploiement multi-stacks, plan de rollback.
