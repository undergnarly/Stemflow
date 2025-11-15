# Production Tracker - Backend

FastAPI backend for the Production Tracker application.

## Stack

- **FastAPI** - Modern Python web framework
- **Prisma** - Type-safe database ORM
- **PostgreSQL** - Database
- **JWT** - Authentication
- **Anthropic Claude** - AI assistant
- **librosa** - Audio analysis

## Structure

```
backend/
├── app/
│   ├── api/
│   │   ├── endpoints/    # API route handlers
│   │   └── deps.py       # Dependencies (auth, etc.)
│   ├── core/
│   │   ├── config.py     # Configuration
│   │   ├── security.py   # Auth utilities
│   │   └── database.py   # DB connection
│   ├── models/           # Business logic models
│   ├── schemas/          # Pydantic schemas
│   ├── services/         # Business logic
│   └── main.py           # FastAPI app
├── prisma/
│   └── schema.prisma     # Database schema
├── tests/                # Tests
├── requirements.txt      # Dependencies
└── Dockerfile            # Container definition
```

## Setup

### Local Development

1. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Set up environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Generate Prisma client**
   ```bash
   prisma generate
   ```

5. **Run migrations**
   ```bash
   prisma migrate dev
   ```

6. **Start server**
   ```bash
   uvicorn app.main:app --reload
   ```

### Docker

```bash
docker build -t production-tracker-backend .
docker run -p 8000:8000 production-tracker-backend
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/refresh` - Refresh token
- `GET /api/auth/me` - Get current user

### Projects
- `GET /api/projects` - List projects
- `POST /api/projects` - Create project
- `GET /api/projects/:id` - Get project
- `PATCH /api/projects/:id` - Update project
- `DELETE /api/projects/:id` - Delete project

### Versions (Phase 2)
- Audio version management endpoints

### Sessions (Phase 2)
- Session tracking endpoints

### AI (Phase 3)
- AI assistant endpoints

### References (Phase 4)
- Reference track endpoints

## Database

### Migrations

```bash
# Create migration
prisma migrate dev --name migration_name

# Apply migrations
prisma migrate deploy

# Reset database
prisma migrate reset
```

### Prisma Studio

```bash
prisma studio
```

## Testing

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app

# Run specific test file
pytest tests/test_auth.py
```

## Code Quality

```bash
# Format code
black app/

# Lint code
ruff check app/

# Type checking
mypy app/
```

## Environment Variables

Required:
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret for JWT signing
- `ANTHROPIC_API_KEY` - Claude API key

Optional:
- `ACCESS_TOKEN_EXPIRE_MINUTES` - Token expiry (default: 60)
- `UPLOAD_DIR` - Upload directory (default: ./uploads)
- `CORS_ORIGINS` - Allowed origins (default: http://localhost:3000)
- `LOG_LEVEL` - Logging level (default: INFO)

## Development

### Adding an Endpoint

1. Create schema in `app/schemas/`
2. Create endpoint in `app/api/endpoints/`
3. Register router in `app/main.py`

### Adding a Service

1. Create service in `app/services/`
2. Implement business logic
3. Use in endpoints via dependency injection

## Production

For production deployment:

1. Set `ENVIRONMENT=production`
2. Use strong `JWT_SECRET`
3. Configure proper CORS origins
4. Set up SSL/TLS
5. Use production-grade database
6. Configure logging and monitoring
