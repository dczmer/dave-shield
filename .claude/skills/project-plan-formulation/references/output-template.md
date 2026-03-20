# Project Plan: Example Project

**Generated**: 2026-03-20
**Version**: 1.0
**Last Updated**: 2026-03-20

## Table of Contents
1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Architecture Overview](#architecture-overview)
4. [Development and Testing Process](#development-and-testing-process)
5. [Conventions and Rules](#conventions-and-rules)
6. [Security Considerations](#security-considerations)

---

## Overview

**What it is:**
A web-based application for managing customer support tickets. It provides a centralized interface for support teams to track, prioritize, and resolve customer issues efficiently.

**Primary users/stakeholders:**
- Support agents (primary users - 50+ agents)
- Support managers (oversight and reporting)
- Customers (indirect - through ticket status visibility)
- Engineering team (maintenance and feature development)

**Scope (IN):**
- Ticket creation, assignment, and tracking
- Priority and status management
- Internal notes and customer-facing responses
- Email notifications
- Basic reporting and analytics
- Integration with email system
- Search and filtering capabilities

**Scope (OUT):**
- Customer self-service portal (phase 2)
- Live chat integration (separate project)
- Advanced AI-powered suggestions (future consideration)
- Mobile native apps (web-responsive only)
- Billing or payment processing

**Key context/constraints:**
- Must launch MVP within 3 months
- Team of 3 engineers
- Must integrate with existing email infrastructure (SendGrid)
- Support team currently using outdated legacy system
- Need to migrate 100k+ historical tickets
- Compliance requirement: GDPR for EU customers

---

## Tech Stack

**Languages:**
- Python 3.11+ (backend)
- TypeScript 5.0+ (frontend)
- SQL (database queries)

**Frameworks & Libraries:**
- Backend: FastAPI 0.104+ (async web framework)
- Frontend: React 18.2+ with Vite
- ORM: SQLAlchemy 2.0+ (async)
- State Management: TanStack Query (React Query)
- UI Components: Radix UI + Tailwind CSS

**Build Tools:**
- Backend: Poetry (dependency management), Pytest (testing)
- Frontend: Vite (bundler), Vitest (testing), ESLint + Prettier
- Docker + Docker Compose (local development)
- GitHub Actions (CI/CD)

**Databases & Storage:**
- PostgreSQL 15+ (primary database)
- Redis 7+ (caching, session storage)
- S3-compatible storage (file attachments)

**External Services:**
- SendGrid (email delivery)
- Sentry (error tracking)
- DataDog (monitoring and logging)

**Development Tools:**
- VS Code (recommended IDE)
- Ruff (Python linting/formatting)
- Black (Python formatting fallback)
- TypeScript strict mode
- Pre-commit hooks (lint, type check, tests)

---

## Architecture Overview

**System Components:**
- **Web API** (FastAPI) - RESTful API, handles business logic
- **Web Frontend** (React) - Single-page application, agent interface
- **Background Workers** (Celery) - Async tasks (emails, notifications)
- **Database** (PostgreSQL) - Persistent storage
- **Cache** (Redis) - Session storage, rate limiting, task queue
- **Email Service** (SendGrid) - Transactional emails
- **File Storage** (S3) - Ticket attachments

**Communication Patterns:**
- Frontend ↔ API: REST over HTTPS (JSON)
- API ↔ Database: SQLAlchemy async ORM
- API ↔ Cache: Redis protocol
- API ↔ Workers: Celery task queue (Redis broker)
- API ↔ External Services: HTTPS REST APIs

**Data Flow:**
1. User action in frontend → API request
2. API validates, processes business logic
3. Database operations via ORM
4. Async tasks queued to Celery workers
5. Workers send emails, process attachments
6. Cache updated for frequently accessed data
7. API returns response → Frontend updates UI

**Deployment Architecture:**
- Containerized microservices (Docker)
- Kubernetes cluster (production)
- Multi-container setup: API (3 replicas), Workers (2 replicas), DB, Redis
- Load balancer (Nginx ingress) → API pods
- Horizontal scaling for API and workers
- Managed PostgreSQL (RDS) and Redis (ElastiCache)

**Key Design Decisions:**
1. **FastAPI over Django** - Better async support, type safety, OpenAPI docs
2. **Postgres over MySQL** - Better JSON support, full-text search capabilities
3. **Celery for background tasks** - Mature ecosystem, retry mechanisms
4. **React over Vue** - Team familiarity, larger ecosystem
5. **Monorepo** - Simpler deployment, shared types between frontend/backend

**Existing Patterns to Follow:**
- RESTful API design consistent with company API guidelines
- Authentication pattern similar to other internal tools (JWT)
- Database migration strategy matches engineering standards (Alembic)

---

## Development and Testing Process

**Environment Setup:**
1. Clone repository
2. Install Python 3.11+, Node.js 18+, Docker Desktop
3. Run `make setup` to install dependencies
4. Copy `.env.example` → `.env` and configure
5. Run `make dev` to start local services
6. Access: Frontend at `localhost:3000`, API at `localhost:8000`, API docs at `localhost:8000/docs`

**Build Process:**
- Backend: `poetry install` → installs dependencies, no compilation
- Frontend: `npm install` → `npm run build` → generates production bundle
- Docker: `docker-compose build` → builds all service images

**Running Locally:**
```bash
# Start all services (DB, Redis, API, Workers, Frontend)
make dev

# Or individual services:
docker-compose up db redis         # Infrastructure
poetry run uvicorn main:app --reload  # API only
npm run dev                         # Frontend only
celery -A worker worker --loglevel=info  # Workers only
```

**Testing:**
- **Unit tests** (Backend): `pytest tests/unit` - Pure function tests, mocked dependencies
- **Unit tests** (Frontend): `npm run test` - Component tests with Vitest
- **Integration tests** (Backend): `pytest tests/integration` - Database and Redis required
- **E2E tests**: `npm run test:e2e` - Playwright tests, full stack running

**Testing Workflow:**
- Run tests before commit: `make test` (runs all backend + frontend tests)
- CI runs tests on all PRs
- Integration tests use test database (auto-created/destroyed)
- E2E tests run in CI with isolated environment

**Debugging:**
- Backend: Use VS Code debugger with FastAPI launch config, or add `breakpoint()` in code
- Frontend: React DevTools + Chrome DevTools
- Database: Query logs in Docker logs, pgAdmin for manual queries
- View logs: `docker-compose logs -f [service]`
- Common issue: Port conflicts → `make clean` to stop all services

**Common Workflows:**
- Feature branch workflow: `main` → `feature/TICKET-123` → PR → merge
- Hot reload: Both API and frontend auto-reload on file changes
- Database changes: Create migration with `alembic revision --autogenerate`, review, then `alembic upgrade head`
- Adding dependencies: Backend (`poetry add`), Frontend (`npm install`)

---

## Conventions and Rules

**Code Organization:**
```
backend/
  app/
    api/          # API routes (one file per resource)
    models/       # SQLAlchemy models
    schemas/      # Pydantic schemas (request/response)
    services/     # Business logic layer
    core/         # Config, dependencies, middleware
    utils/        # Shared utilities
  tests/
    unit/         # Unit tests mirror app/ structure
    integration/  # Integration tests
  alembic/        # Database migrations

frontend/
  src/
    components/   # Reusable UI components
    pages/        # Page-level components
    hooks/        # Custom React hooks
    api/          # API client code
    types/        # TypeScript type definitions
    utils/        # Helper functions
  tests/          # Component and E2E tests
```

**Naming Conventions:**
- **Files (Python):** `snake_case.py` - Example: `ticket_service.py`
- **Files (TypeScript):** `PascalCase.tsx` for components, `camelCase.ts` for utilities
- **Classes (Python):** `PascalCase` - Example: `TicketService`, `TicketModel`
- **Functions/Methods:** `snake_case` (Python), `camelCase` (TypeScript)
- **Variables:** `snake_case` (Python), `camelCase` (TypeScript)
- **Constants:** `UPPER_SNAKE_CASE` - Example: `MAX_RETRIES = 3`
- **Database tables:** `snake_case` - Example: `tickets`, `user_assignments`

**Documentation Standards:**
- All public functions/classes require docstrings (Google style for Python)
- TypeScript: Use JSDoc for complex functions
- README in each major directory explaining its purpose
- API endpoints documented via FastAPI auto-docs (docstrings appear in Swagger UI)
- Architecture Decision Records (ADRs) for major decisions in `docs/adr/`

**Code Review Practices:**
- All changes require PR approval from at least one other engineer
- PR must include: Summary, Testing instructions, Screenshots (for UI changes)
- Automated checks must pass: linting, type checking, tests
- Review checklist: correctness, test coverage, documentation, security
- Keep PRs small (<400 lines preferred) for faster review

**Antipatterns to Avoid:**
- **God objects** - Keep classes focused, single responsibility
- **Business logic in API routes** - Use service layer
- **Synchronous I/O in async functions** - Use async clients
- **Hardcoded configuration** - Use environment variables
- **Direct database access from frontend** - Always through API
- **Missing error handling** - All API calls should handle errors
- **Overly complex React components** - Split into smaller components

**File/Folder Organization:**
- Group by feature/domain, not by type (e.g., `tickets/` contains models, schemas, services for tickets)
- Keep related files close (test files next to implementation)
- Shared code in dedicated directories (`utils/`, `core/`)
- Configuration files at project root

---

## Security Considerations

**Authentication:**
- JWT tokens for API authentication
- Token expiry: 1 hour access token, 7 day refresh token
- Login endpoint: POST `/auth/login` (username/password) → returns JWT
- Logout: Token blacklist in Redis (tracks revoked tokens)
- Password requirements: min 12 characters, complexity rules enforced

**Authorization:**
- Role-based access control (RBAC)
- Roles: Agent, Manager, Admin
- Permissions checked at API endpoint level (FastAPI dependencies)
- Row-level security: Agents only see tickets assigned to them or their team
- Managers can see all team tickets, Admins see all tickets

**Data Protection:**
- All API communication over HTTPS (TLS 1.2+)
- Sensitive fields encrypted at rest (database level encryption)
- PII fields: customer email, name - handled per GDPR requirements
- File uploads: scanned for malware, size limits enforced (10MB max)
- Data retention: Tickets archived after 3 years, PII anonymized
- Passwords: Hashed with bcrypt (cost factor 12)

**Known Vulnerabilities/Mitigations:**
- **SQL Injection** - Mitigated by ORM (SQLAlchemy), parameterized queries
- **XSS** - Mitigated by React auto-escaping, CSP headers
- **CSRF** - Mitigated by SameSite cookies, CORS policy
- **Rate limiting** - 100 requests/minute per user (Redis-based)
- **Dependency vulnerabilities** - Monitored via Dependabot, monthly security reviews

**Security Review Requirements:**
- Security review required for changes to: auth system, permissions, encryption, external integrations
- Annual penetration testing by external firm
- Quarterly internal security audits
- All PRs automatically scanned by Snyk

**Secrets Management:**
- Environment variables for configuration (never commit secrets)
- Production secrets stored in AWS Secrets Manager
- Local development: `.env` file (gitignored, template in `.env.example`)
- Rotation: Database credentials rotated every 90 days
- API keys for external services: rotated on compromise or annually

**Access Control Patterns:**
- Principle of least privilege: users get minimum required permissions
- Permission checks: `@require_permission("ticket:read")` decorator on endpoints
- Audit logging: All sensitive actions logged (who, what, when)
- Session timeout: 8 hours of inactivity → auto-logout
- Failed login attempts: 5 failures → temporary account lock (15 minutes)

---

## Appendix

### Migration Strategy

Plan for migrating 100k+ historical tickets from legacy system:
1. Export legacy data to CSV
2. Data cleaning script (normalize formats)
3. Batch import via management command
4. Validation and reconciliation
5. Gradual rollout to teams

### Future Considerations

Features explicitly deferred to future phases:
- Customer self-service portal
- Mobile native applications
- Advanced AI suggestions
- Real-time collaboration features
- Custom workflow automation

### Team Contacts

- Technical Lead: [Name]
- Product Owner: [Name]
- DevOps Contact: [Name]

---

*This document should be updated as the project evolves. Last reviewed: 2026-03-20*
