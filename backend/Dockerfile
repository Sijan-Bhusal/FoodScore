FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    libpq-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip setuptools wheel

# Copy and install requirements
COPY requirements-production.txt .
RUN pip install --no-cache-dir -r requirements-production.txt

# Copy application code
COPY . .

# Create non-root user and log directory
RUN useradd -m -u 1000 appuser && mkdir -p /var/log/foodscore && chown -R appuser:appuser /app /var/log/foodscore
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
