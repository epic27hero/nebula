import subprocess
import time
import os
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()

# ================= CONFIG =================
NAMESPACE = "argocd"
NEW_PASSWORD = os.getenv("GRAFANA_PASSWORD")
SERVER = "192.168.0.202:80"
# ==========================================


def run(cmd):
    print(f"\n▶ {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ ERROR:\n{result.stderr}")
        exit(1)
    return result.stdout.strip()


def main():
    print("\n=== 🔐 ARGO CD ADMIN PASSWORD RESET (FIXED VERSION) ===")

    # 1️⃣ Generate bcrypt hash (CORRECT METHOD)
    bcrypt = run(
        f"htpasswd -bnBC 10 '' '{NEW_PASSWORD}' | tr -d ':\n'"
    )
    print(f"✅ Bcrypt Hash Generated")

    # 2️⃣ Patch argocd-secret (PASSWORD + MTIME)
    mtime = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

    run(f"""
kubectl -n {NAMESPACE} patch secret argocd-secret \
  -p '{{
    "stringData": {{
      "admin.password": "{bcrypt}",
      "admin.passwordMtime": "{mtime}"
    }}
  }}'
""")

    print("✅ argocd-secret patched")

    # 3️⃣ Restart argocd-server
    run(f"kubectl -n {NAMESPACE} rollout restart deployment argocd-server")
    print("⏳ Waiting for server to restart...")
    time.sleep(30)

    # 4️⃣ Clear local CLI cache (CRITICAL)
    run("rm -rf ~/.config/argocd")
    print("🧹 CLI cache cleared")

    # 5️⃣ Login (HTTP + plaintext + grpc-web)
    run(f"""
argocd login {SERVER} \
  --username admin \
  --password '{NEW_PASSWORD}' \
  --plaintext \
  --grpc-web
""")

    print("🎉 LOGIN SUCCESS")

    # 6️⃣ Verify
    apps = run("argocd app list")
    print("\n📦 Applications:")
    print(apps)

    print("\n✅ DONE — UI + CLI AUTH FIXED")


if __name__ == "__main__":
    main()
