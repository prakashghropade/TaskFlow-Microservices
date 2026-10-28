# TaskFlow Microservices

TaskFlow is a DevSecOps-focused, TypeScript and Node.js microservices application for user authentication, task management, file attachments, and task workflow history. Its delivery workflow integrates code quality and container security checks with GitOps-based Kubernetes deployment.

## Architecture

![TaskFlow microservices architecture](architecture-diagrams/microservices-architecture-diagram.jpg)

The services share common database, Kafka, authentication, logging, and HTTP utilities from the `packages/shared` workspace package.

| Component | Default port | Responsibility |
| --- | ---: | --- |
| API gateway | 3000 | Public entry point; routes requests, applies rate limiting and security headers, verifies JWTs, and enforces role-based access |
| Auth service | 3001 | User registration, login, and current-user endpoint |
| Task service | 3002 | Task creation, listing, retrieval, and deletion |
| Media service | 3003 | Task attachment uploads and listing; stores files in an S3-compatible object store |
| Workflow service | 3004 | Consumes task and attachment events from Kafka and provides task workflow history |
| Kafka | 9092 | Event transport between services |
| PostgreSQL | external | Persists users, tasks, attachments, and workflows |

The gateway adds a shared secret when proxying requests to internal services. For protected routes it validates the bearer token and forwards the authenticated user identity to the service. Task and media events are published to Kafka and consumed by the workflow service.

## DevSecOps delivery

Security and quality checks are incorporated into the CI/CD and deployment workflow:

- **Continuous integration:** GitHub Actions workflows run for service changes on pushes to `main` and pull requests, using a shared service pipeline.
- **Static analysis and quality gates:** SonarQube analyzes the code, and the pipeline stops if the configured quality gate fails.
- **Container vulnerability scanning:** Trivy scans built images for **HIGH** and **CRITICAL** vulnerabilities, fails the pipeline when findings are detected, and ignores unfixed vulnerabilities. Results are uploaded to GitHub in SARIF format.
- **Controlled image publishing:** Docker images are pushed only after the preceding pipeline checks succeed. Registry and SonarQube credentials are provided through GitHub Actions secrets.
- **GitOps deployment:** Helm charts describe the Kubernetes workloads, and Argo CD synchronizes the environment configuration from Git with automated self-healing.
- **Cloud operations:** The repository includes AWS EKS deployment configuration, Kubernetes health checks and autoscaling, and External Secrets integration with AWS Secrets Manager.
- **Application security:** The API gateway applies rate limiting and security headers, verifies JWTs, enforces role-based access, and authenticates internal service requests with a gateway secret.

The workflow is defined in `.github/workflows/` and the deployment configuration is under `k8s-gitops/`. Configure GitHub Actions secrets and cloud credentials in the deployment environment; do not store live credentials in source files or screenshots.

## Platform screenshots

These screenshots illustrate code-quality reporting and the Kubernetes/GitOps environment. The SonarQube dashboard is a point-in-time view; its findings and quality-gate status can change between analyses.

### Code quality and security

The SonarQube project overview shows the quality-gate status and code-quality metrics at the time of capture.

![SonarQube project overview and quality gate](architecture-diagrams/WhatsApp%20Image%202026-10-28%20at%209.29.24%20PM.jpeg)

The issue view shows security findings identified by static analysis for follow-up and remediation.

![SonarQube security and code issue list](architecture-diagrams/WhatsApp%20Image%202026-10-28%20at%209.29.24%20PM%20%281%29.jpeg)

### GitOps and Kubernetes

Argo CD shows the development applications and their reported synchronization and health status.

![Argo CD development applications](architecture-diagrams/WhatsApp%20Image%202026-10-28%20at%209.29.26%20PM.jpeg)

This second view continues the Argo CD application list, including the workflow service.

![Argo CD development applications continued](architecture-diagrams/WhatsApp%20Image%202026-10-28%20at%209.29.26%20PM%20%281%29.jpeg)

The AWS console screenshots show EKS cluster configuration and its available cluster resources.

![AWS EKS cluster overview](architecture-diagrams/WhatsApp%20Image%202026-10-28%20at%209.29.27%20PM.jpeg)

![AWS EKS cluster resources and configuration](architecture-diagrams/WhatsApp%20Image%202026-10-28%20at%209.29.27%20PM%20%281%29.jpeg)

The terminal output shows Horizontal Pod Autoscaler resources reported for the microservices namespace.

![Kubernetes Horizontal Pod Autoscaler status](architecture-diagrams/WhatsApp%20Image%202026-10-28%20at%209.29.27%20PM%20%283%29.jpeg)

### TLS and DNS

The AWS Certificate Manager view shows certificate issuance and domain validation status.

![AWS Certificate Manager certificate status](architecture-diagrams/WhatsApp%20Image%202026-10-28%20at%209.29.25%20PM.jpeg)

The Route 53 view shows DNS records for the project domain.

![Amazon Route 53 hosted-zone records](architecture-diagrams/WhatsApp%20Image%202026-10-28%20at%209.29.27%20PM%20%284%29.jpeg)

## Technology

- Node.js 20 or later, TypeScript, and Express
- npm workspaces for the applications and shared package
- PostgreSQL for relational data
- KafkaJS and Apache Kafka for asynchronous events
- S3-compatible object storage for attachments
- Docker for the local Kafka broker and container builds
- Helm and Argo CD manifests for Kubernetes/GitOps deployments

## Prerequisites

- Node.js 20+ and npm
- Docker with the Docker Compose plugin
- A PostgreSQL database
- An S3-compatible storage service and bucket to use attachment uploads

## Local setup

1. Install the workspace dependencies from the repository root:

   ```sh
   npm ci
   ```

2. Create a root-level `.env` file. Keep credentials private and do not commit this file.

   ```dotenv
   # PostgreSQL connection string used by the services and migrations
   DATABASE_URL=postgresql://postgres:password@localhost:5432/taskflow

   # Authentication and internal gateway-to-service authentication
   JWT_SECRET=replace-with-a-long-random-secret
   JWT_EXPIRES_IN=1h
   GATEWAY_SECRET=replace-with-a-different-long-random-secret

   # Kafka (the default matches the included local Compose setup)
   KAFKA_BROKERS=localhost:9092

   # S3-compatible object storage (required for attachment uploads)
   AWS_ENDPOINT_URL_S3=http://localhost:9000
   AWS_ACCESS_KEY_ID=your-access-key
   AWS_SECRET_ACCESS_KEY=your-secret-key
   AWS_REGION=us-east-1
   STORAGE_BUCKET=taskflow-attachments

   # Optional logging level: trace, debug, info, warn, or error
   LOG_LEVEL=info
   ```

   The gateway and service ports default to `3000`–`3004`. To override them, set `PORT`, `AUTH_PORT`, `TASK_PORT`, `MEDIA_PORT`, or `WORKFLOW_PORT`. If the services are not on their default local addresses, set `AUTH_SERVICE_URL`, `TASK_SERVICE_URL`, `MEDIA_SERVICE_URL`, and `WORKFLOW_SERVICE_URL` for the gateway.

3. Start the local Kafka broker:

   ```sh
   npm run kafka:up
   ```

   This Compose file starts Kafka only; PostgreSQL and S3-compatible storage must be available separately. To stop Kafka, run `npm run kafka:down`; to follow its logs, run `npm run kafka:logs`.

4. Apply the database migrations:

   ```sh
   npm run db:migrate
   ```

   The migration runner applies the ordered SQL files in `sql/` and records completed migrations in `schema_migrations`. It skips migrations that have already run.

5. Start each application in a separate terminal from the repository root:

   ```sh
   npm run dev:gateway
   npm run dev:auth
   npm run dev:task
   npm run dev:media
   npm run dev:workflow
   ```

   The gateway is available at `http://localhost:3000`. Each service also exposes a `/health` endpoint on its own port.

## API overview

Send application requests through the API gateway rather than calling internal services directly.

| Gateway path | Operations |
| --- | --- |
| `/auth` | Register, log in, and retrieve the authenticated user |
| `/tasks` | Create, list, retrieve, and delete tasks |
| `/tasks/.../attachments` | Upload and list task attachments |
| `/tasks/.../workflows` | Retrieve workflow history for a task |

Protected endpoints require an `Authorization: Bearer <token>` header. Authentication endpoints intended for registration and login are public. The gateway applies role-based access control to protected API routes.

## Build

Build the shared package before building the services that depend on it:

```sh
npm run build -w shared
npm run build -w api-gateway
npm run build -w auth-service
npm run build -w task-service
npm run build -w media-service
npm run build -w workflow-service
```

The root `Dockerfile` builds one service per image. Supply the workspace name through its `SERVICE` build argument, for example `api-gateway` or `auth-service`.

## Deployment

The `k8s-gitops/` directory contains Helm charts and Argo CD application definitions for development, staging, and production environments. Review and configure the environment-specific Helm values, AWS access, and secrets before deploying.

## Repository layout

```text
apps/                    API gateway and four backend services
packages/shared/         Shared TypeScript utilities
sql/                     PostgreSQL schema migrations
docker/                  Local Kafka Compose configuration
architecture-diagrams/   Project architecture diagram
k8s-gitops/              Helm charts and Argo CD GitOps configuration
AI_Implimentaion/        Python AI implementation files
```
