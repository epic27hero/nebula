from fastapi import FastAPI
import os, socket
from prometheus_client import Counter, generate_latest
from fastapi import Response

app = FastAPI(title="FastAPI Demo")

# Prometheus metrics
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests"
)


@app.middleware("http")
async def count_requests(request, call_next):
    REQUEST_COUNT.inc()
    response = await call_next(request)
    return response

@app.get("/")
def root():
    return {
        "message": "FastAPI running on Kubernetes on ${hostname -I}",
        "env": os.getenv("ENV", "unknown"),
        "host": socket.gethostname()
    }

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/metrics")
def metrics():
    return Response(
        generate_latest(),
        media_type="text/plain"
    )
