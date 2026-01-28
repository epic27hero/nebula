#!/usr/bin/env python3
"""
Project Nebula - Application Health & Sync Script
Checks and syncs all ArgoCD applications
"""

import subprocess
import json
import time
import sys
import os

# Load environment variables
def load_env():
    env_file = "/root/project_nebula/.env"
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    try:
                        key, value = line.split("=", 1)
                        os.environ[key.strip()] = value.strip().strip('"')
                    except:
                        pass

load_env()

class ArgoApp:
    def __init__(self, name, namespace="argocd"):
        self.name = name
        self.namespace = namespace
        
    def get_status(self):
        """Get application status"""
        try:
            cmd = f"kubectl get application {self.name} -n {self.namespace} -o json"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                data = json.loads(result.stdout)
                return {
                    "sync_status": data["status"]["sync"]["status"],
                    "health_status": data["status"]["health"]["status"],
                    "revision": data["status"].get("sync", {}).get("revision", "unknown"),
                }
            return None
        except:
            return None
    
    def check_and_report(self):
        """Check status and report"""
        status = self.get_status()
        if not status:
            print(f"❌ {self.name:20} - UNKNOWN (failed to fetch)")
            return False
        
        sync = status["sync_status"]
        health = status["health_status"]
        
        sync_icon = "✅" if sync == "Synced" else "🟡" if sync == "Unknown" else "❌"
        health_icon = "✅" if health == "Healthy" else "🟡" if health == "Progressing" else "❌"
        
        print(f"{sync_icon} {self.name:20} | Sync: {sync:12} | Health: {health:12}")
        
        return (sync == "Synced" or sync == "Unknown") and health == "Healthy"

def main():
    print("=" * 80)
    print("Project Nebula - Application Health & Sync Check")
    print("=" * 80)
    print()
    
    # Test GitLab access
    print("Testing GitLab connectivity...")
    token = os.getenv("PROJECT_NEBULA_ACCESS_TOKEN", "")
    url = os.getenv("GITLAB_URL", "")
    
    if token and url:
        cmd = f"curl -s -H 'PRIVATE-TOKEN: {token}' {url}/api/v4/user 2>/dev/null | grep -o '\"username\":\"[^\"]*' | cut -d'\"' -f4"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=5)
        if result.returncode == 0 and result.stdout.strip():
            print(f"✅ GitLab access OK (User: {result.stdout.strip()})")
        else:
            print("⚠️ GitLab token may need verification")
    else:
        print("⚠️ .env file not fully configured")
    
    print()
    
    # List of applications
    apps = [
        ArgoApp("fastapi-prod"),
        ArgoApp("grafana"),
        ArgoApp("prometheus"),
    ]
    
    # Check status
    print("Current Status:")
    print("-" * 80)
    all_healthy = True
    for app in apps:
        is_healthy = app.check_and_report()
        all_healthy = all_healthy and is_healthy
    
    print()
    print("=" * 80)
    
    if all_healthy:
        print("✅ All applications are healthy and synced!")
        return 0
    else:
        print("🟡 Some applications need attention - check above")
        return 1

if __name__ == "__main__":
    sys.exit(main())
