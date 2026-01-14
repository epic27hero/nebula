from fastapi import FastAPI
import os, socket, subprocess
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
    # Get hostname and IP
    hostname = socket.gethostname()
    try:
        ip_address = subprocess.check_output(['hostname', '-I']).decode().strip()
    except:
        ip_address = socket.gethostbyname(hostname)
    
    return {
        "message": f"FastAPI running on Kubernetes on {hostname} ({ip_address})",
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
