# FoodScore

A comprehensive food health scoring system that analyzes product ingredients, nutrients, and additives to provide nutritional insights and health recommendations.

## Quick Start

### Prerequisites

- Docker and Docker Compose (version 1.29+)
- Git

### Setup and Run

```bash
git clone <repository-url>
cd FoodScore

# Start all services (PostgreSQL + FastAPI backend)
docker-compose up -d

# Verify services are running
docker-compose ps
```

The backend API will be available at `http://localhost:8000` after services start.

### Access API Documentation

Once running, visit the interactive API documentation:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Project Overview

### Architecture

```
FoodScore/
├── backend/
│   ├── app/
│   │   ├── api/              # API route handlers
│   │   ├── services/         # Business logic
│   │   ├── models/           # Database models (SQLAlchemy)
│   │   ├── schemas/          # Request/response validation (Pydantic)
│   │   ├── db/               # Database configuration
│   │   ├── ml/               # Scoring algorithms
│   │   ├── main.py           # FastAPI application entry
│   │   └── config.py         # Configuration management
│   ├── requirements.txt       # Python dependencies
│   └── Dockerfile
├── flutter_app/              # Flutter mobile application
├── database/
│   └── schema.sql           # Database schema definition
├── docker-compose.yml        # Multi-container orchestration
├── .env.example             # Environment configuration template
└── README.md                # This file
```

### Technology Stack

- **Backend**: FastAPI (Python), SQLAlchemy ORM
- **Database**: PostgreSQL 15
- **Frontend**: Flutter
- **Containerization**: Docker & Docker Compose

## Common Operations

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f postgres
```

### Stop Services

```bash
docker-compose stop
```

### Restart Services

```bash
docker-compose restart
```

### Clean Up (Remove Containers and Volumes)

```bash
docker-compose down -v
```

### Access Database Shell

```bash
docker-compose exec postgres psql -U foodscore -d foodscore
```

## Configuration

### Environment Variables

Configuration is managed through the `.env` file. Copy `.env.example` and update values as needed:

```bash
cp .env.example .env
```

Default configuration for development:
- Database: `postgresql://foodscore:foodscore_dev_password@postgres:5432/foodscore`
- Backend Port: `8000`
- Database Port: `5433` (mapped from container port 5432)

## API Endpoints

### Products

- `GET /api/products` — List all products
- `POST /api/products` — Create a new product
- `GET /api/products/{product_id}` — Get product details
- `DELETE /api/products/{product_id}` — Delete a product

### Scoring

- `POST /api/score` — Calculate food health score
- `GET /api/score/{product_id}` — Retrieve product score

### Search

- `GET /api/search` — Search products by name or barcode

## Troubleshooting

### Port Already in Use

If port 8000 or 5433 is in use:

1. Option A: Modify port mappings in `docker-compose.yml`
2. Option B: Stop conflicting services before running `docker-compose up`

### Database Connection Failed

```bash
# Check PostgreSQL container status
docker-compose ps

# View database logs
docker-compose logs postgres

# Restart database service
docker-compose restart postgres
```

### Backend Not Responding

```bash
# Check backend logs
docker-compose logs backend

# Verify container is running
docker-compose ps

# Rebuild and restart
docker-compose up -d --build
```

## Development

### Making Backend Changes

Code changes are automatically reloaded (hot-reload enabled). Check logs to verify:

```bash
docker-compose logs -f backend
```

### Adding Python Dependencies

1. Update `backend/requirements.txt`
2. Rebuild the backend image:

```bash
docker-compose build backend
docker-compose up -d
```

## Additional Resources

- See [PROJECT_REVIEW.md](PROJECT_REVIEW.md) for known issues and recommendations
- See [DOCKER_SETUP.md](DOCKER_SETUP.md) for advanced Docker operations

## License

This project is part of a college assignment.
