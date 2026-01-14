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
    # Get hostname
    hostname = socket.gethostname()
    
    # Pod and Node details from Kubernetes environment variables
    pod_ip = os.getenv("POD_IP", "unknown")
    node_ip = os.getenv("NODE_IP", "unknown")
    node_name = os.getenv("NODE_NAME", "unknown")
    
    return {
        "message": "FastAPI running on Kubernetes",
        "env": os.getenv("ENV", "unknown"),
        
        # Pod details
        "pod_name": hostname,
        "pod_ip": pod_ip,
        
        # Node / Server details
        "node_name": node_name,
        "node_ip": node_ip,
        "server_ip": node_ip,
        "version": "v1.0.3"
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
