# Quickstart

Get FoodScore running locally with Docker Compose.

## 1. Configure environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:

```
DB_PASSWORD=your_password
SECRET_KEY=your-secret-key-here
```

`SECRET_KEY` is required — the backend will refuse to start without it.

## 2. Start services

```bash
docker-compose up -d --build
```

This starts PostgreSQL (port `5433`) and the FastAPI backend (port `8000`), applying `database/schema.sql` automatically.

## 3. Verify

```bash
curl http://localhost:8000/health
docker-compose ps
```

## 4. Try the scan endpoint

```bash
curl http://localhost:8000/products/scan/3017620425035
```

## Useful commands

```bash
# View backend logs
docker-compose logs -f backend

# Open a database shell
docker-compose exec postgres psql -U foodscore -d foodscore

# Open a shell in the backend container
docker-compose exec backend bash

# Stop services
docker-compose down

# Stop and delete all data (including the database volume)
docker-compose down -v
```

## Next steps

- Full API reference: [API.md](API.md)
- Architecture, setup details, and scoring algorithm: [README.md](README.md)
