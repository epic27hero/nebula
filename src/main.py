from fastapi import FastAPI, Response
import os
import socket
import time
import psutil

from prometheus_client import Counter, Histogram, generate_latest

# Kubernetes client
from kubernetes import client, config
from kubernetes.client.exceptions import ApiException


# -----------------------------------------------------------------------------
# App metadata
# -----------------------------------------------------------------------------
APP_NAME = "fastapi-demo"
APP_VERSION = os.getenv("APP_VERSION", "v1.0.6")
BUILD_TIME = os.getenv("BUILD_TIME", "unknown")
START_TIME = time.time()

app = FastAPI(title="FastAPI Kubernetes Observability Demo")


# -----------------------------------------------------------------------------
# Prometheus Metrics
# -----------------------------------------------------------------------------
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status"]
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency",
    ["path"]
)


@app.middleware("http")
async def metrics_middleware(request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start

    REQUEST_COUNT.labels(
        method=request.method,
        path=request.url.path,
        status=response.status_code
    ).inc()

    REQUEST_LATENCY.labels(
        path=request.url.path
    ).observe(duration)

    return response


# -----------------------------------------------------------------------------
# Kubernetes client initialization
# -----------------------------------------------------------------------------
def get_k8s_client():
    try:
        config.load_incluster_config()
        return client.CoreV1Api(), None
    except Exception as e:
        return None, str(e)


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def get_resource_usage():
    process = psutil.Process()
    return {
        "cpu_percent": psutil.cpu_percent(interval=0.1),
        "memory_mb": round(process.memory_info().rss / 1024 / 1024, 2)
    }


def get_cluster_info():
    v1, err = get_k8s_client()
    if err:
        return {"error": "Kubernetes client not available", "details": err}

    result = {
        "total_pods": 0,
        "total_namespaces": 0,
        "all_pod_ips": [],
        "namespaces": {}
    }

    try:
        namespaces = v1.list_namespace()
        result["total_namespaces"] = len(namespaces.items)

        for ns in namespaces.items:
            ns_name = ns.metadata.name
            result["namespaces"][ns_name] = []

            pods = v1.list_namespaced_pod(ns_name)
            for pod in pods.items:
                if pod.status.pod_ip:
                    result["all_pod_ips"].append(pod.status.pod_ip)
                    result["namespaces"][ns_name].append({
                        "pod_name": pod.metadata.name,
                        "pod_ip": pod.status.pod_ip,
                        "node_name": pod.spec.node_name
                    })

        result["total_pods"] = len(result["all_pod_ips"])
        return result

    except ApiException as e:
        return {
            "error": "RBAC permission missing",
            "details": e.reason
        }


# -----------------------------------------------------------------------------
# Routes
# -----------------------------------------------------------------------------
@app.get("/")
def root():
    hostname = socket.gethostname()

    return {
        "message": "FastAPI running on Kubernetes",

        "environment": os.getenv("ENV", "unknown"),

        "app": {
            "name": APP_NAME,
            "version": APP_VERSION,
            "build_time": BUILD_TIME,
            "uptime_seconds": int(time.time() - START_TIME)
        },

        "pod": {
            "name": hostname,
            "ip": os.getenv("POD_IP", "unknown"),
            "namespace": os.getenv("POD_NAMESPACE", "unknown"),
            "service_account": os.getenv("SERVICE_ACCOUNT", "unknown")
        },

        "node": {
            "name": os.getenv("NODE_NAME", "unknown"),
            "ip": os.getenv("NODE_IP", "unknown")
        },

        "resources": get_resource_usage()
    }


# @app.get("/cluster")
# def cluster_details():
#     """
#     Requires RBAC:
#       - list namespaces
#       - list pods
#     """
#     return get_cluster_info()


@app.get("/health")
def health():
    return {"status": "alive"}


@app.get("/ready")
def readiness():
    return {
        "status": "ready",
        "checks": {
            "kubernetes_api": "ok",
            "metrics": "ok"
        }
    }


@app.get("/metrics")
def metrics():
    return Response(
        generate_latest(),
        media_type="text/plain"
    )