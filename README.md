# Production Tracker

An AI-powered production assistant that integrates with Ableton Live to help music producers finish tracks by tracking progress, providing intelligent suggestions, and preventing creative blocks.

## Project Overview

Production Tracker is designed for music producers (primarily jungle, drum & bass, and soundsystem music) who:
- Have many unfinished projects
- Get stuck in perfectionism loops
- Need help deciding when a track is done
- Want to learn from their successful patterns

### Core Features

- **Automatic Session Tracking**: Monitor your production sessions without manual input
- **AI-Powered Suggestions**: Get intelligent recommendations based on your workflow patterns
- **Version Control**: Track changes with audio analysis
- **Context-Aware Assistance**: Receive help based on your specific workflow
- **Proactive Intervention**: Get alerts when stuck in creative blocks

## Tech Stack

### Backend
- **FastAPI** - High-performance Python web framework
- **PostgreSQL** - Relational database
- **Prisma** - Type-safe ORM
- **Anthropic Claude** - AI assistant
- **librosa, pyloudnorm** - Audio analysis

### Frontend
- **Next.js 14** - React framework with App Router
- **TypeScript** - Type-safe JavaScript
- **shadcn/ui** - UI component library
- **Tailwind CSS** - Utility-first CSS
- **Zustand** - State management
- **Wavesurfer.js** - Audio visualization

## Project Structure

```
stemflow/
├── backend/              # FastAPI backend
│   ├── app/
│   │   ├── api/         # API endpoints
│   │   ├── core/        # Core utilities
│   │   ├── models/      # Database models
│   │   ├── schemas/     # Pydantic schemas
│   │   └── services/    # Business logic
│   ├── prisma/          # Database schema
│   └── tests/           # Backend tests
├── frontend/            # Next.js frontend
│   └── src/
│       ├── app/         # Next.js app routes
│       ├── components/  # React components
│       ├── hooks/       # Custom hooks
│       ├── lib/         # Utilities
│       ├── stores/      # Zustand stores
│       └── types/       # TypeScript types
└── docker-compose.yml   # Development environment
```

## Getting Started

### Prerequisites

- Docker & Docker Compose
- Node.js 20+ (if running frontend locally)
- Python 3.11+ (if running backend locally)
- pnpm (for frontend package management)

### Quick Start with Docker

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd stemflow
   ```

2. **Set up environment variables**
   ```bash
   # Backend
   cp backend/.env.example backend/.env
   # Edit backend/.env and add your ANTHROPIC_API_KEY

   # Frontend
   cp frontend/.env.example frontend/.env.local
   ```

3. **Start the services**
   ```bash
   docker-compose up -d
   ```

4. **Access the application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - API Docs: http://localhost:8000/docs

### Development Setup (Without Docker)

#### Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env and configure your settings

# Generate Prisma client
prisma generate

# Run migrations
prisma migrate dev

# Start development server
uvicorn app.main:app --reload
```

#### Frontend

```bash
cd frontend

# Install dependencies
pnpm install

# Set up environment variables
cp .env.example .env.local

# Start development server
pnpm dev
```

## Development Phases

### Phase 1: Foundation (Current)
- ✅ Project structure setup
- ✅ Database schema
- ✅ Basic authentication
- ✅ Project CRUD operations
- 🔄 Docker development environment

### Phase 2: Core Features
- Version control with audio upload
- Audio analysis pipeline
- Session tracking
- Real-time WebSocket communication

### Phase 3: AI Integration
- Claude API integration
- Pattern detection
- Stuck detection
- AI chat interface

### Phase 4: Advanced Features
- Voice notes
- Reference track comparison
- Advanced analytics
- Pattern learning

### Phase 5: Polish
- Performance optimization
- UX refinements
- Mobile responsiveness
- Production deployment

## API Documentation

Once the backend is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Database Migrations

```bash
# Create a new migration
cd backend
prisma migrate dev --name migration_name

# Apply migrations
prisma migrate deploy

# Reset database (WARNING: destructive)
prisma migrate reset
```

## Testing

### Backend Tests
```bash
cd backend
pytest
```

### Frontend Tests
```bash
cd frontend
pnpm test
```

## Contributing

This is a development project. See the specification document for detailed implementation guidelines.

## Environment Variables

### Backend
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret key for JWT tokens
- `ANTHROPIC_API_KEY` - Claude API key
- `UPLOAD_DIR` - Directory for file uploads
- `CORS_ORIGINS` - Allowed CORS origins

### Frontend
- `NEXT_PUBLIC_API_URL` - Backend API URL
- `NEXT_PUBLIC_WS_URL` - WebSocket server URL

## License

[License information to be added]

## Support

For issues and questions, please refer to the project documentation or create an issue in the repository.
