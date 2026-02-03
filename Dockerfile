# Build stage
FROM python:3.11-slim AS builder
WORKDIR /app
COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Final image
FROM python:3.11-slim
WORKDIR /app

# Build arguments for metadata (injected by CI/CD)
ARG APP_VERSION
ARG BUILD_TIME
ARG IMAGE_TAG

# Set environment variables from build args (available at runtime)
ENV APP_VERSION=${APP_VERSION}
ENV BUILD_TIME=${BUILD_TIME}
ENV IMAGE_TAG=${IMAGE_TAG}

# Copy python libs AND executables
COPY --from=builder /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=builder /usr/local/bin /usr/local/bin

RUN useradd -m -u 1000 appuser
USER appuser

COPY src/ .
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
