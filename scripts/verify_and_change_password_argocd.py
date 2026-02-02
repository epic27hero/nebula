import subprocess
import json
import time
from datetime import datetime

# Configuration
NAMESPACE = "argocd"
NEW_PASSWORD = "SouvikFactentry@7#"
SERVER_IP = "192.168.0.202"

def run_command(cmd):
    """Executes shell commands and returns output."""
    try:
        result = subprocess.run(cmd, shell=True, check=True, capture_output=True, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"❌ Error executing: {cmd}\n{e.stderr}")
        return None

def main():
    print("--- 🔍 Step 1: Verifying Argo CD Components ---")
    
    # 1. Check Pod Status
    pod_check = run_command(f"kubectl -n {NAMESPACE} get pods -l app.kubernetes.io/name=argocd-server -o json")
    if pod_check:
        pods = json.loads(pod_check).get('items', [])
        if pods and pods[0]['status']['phase'] == "Running":
            print(f"✅ Pod {pods[0]['metadata']['name']} is Running.")
        else:
            print("⚠️ Warning: argocd-server pod is not in a steady state.")

    # 2. Check Service External IP
    svc_check = run_command(f"kubectl -n {NAMESPACE} get svc argocd-server -o json")
    if svc_check:
        svc = json.loads(svc_check)
        ext_ip = svc.get('status', {}).get('loadBalancer', {}).get('ingress', [{}])[0].get('ip')
        print(f"✅ Service found. External IP: {ext_ip or 'Not assigned'}")

    print("\n--- 🔐 Step 2: Generating Bcrypt Hash ---")
    
    bcrypt_hash = run_command(f"argocd account bcrypt --password '{NEW_PASSWORD}'")
    if not bcrypt_hash:
        print("❌ Failed to generate bcrypt hash.")
        return
    print(f"✅ Hash generated: {bcrypt_hash}")

    print("\n--- 🛠️ Step 3: Patching Secret ---")
    
    mtime = datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ')
    patch_payload = {
        "stringData": {
            "admin.password": bcrypt_hash,
            "admin.passwordMtime": mtime
        }
    }
    patch_cmd = f"kubectl -n {NAMESPACE} patch secret argocd-secret -p '{json.dumps(patch_payload)}'"
    
    if run_command(patch_cmd):
        print("✅ argocd-secret patched successfully.")

    print("\n--- 🔄 Step 4: Restarting Server & Waiting ---")
    
    run_command(f"kubectl -n {NAMESPACE} rollout restart deployment argocd-server")
    print("⏳ Restart triggered. Waiting 30 seconds for pod initialization...")
    time.sleep(30)

    print("\n--- 🚀 Step 5: Attempting Login ---")
    
    # We use 'yes' to pipe into the TLS warning prompt
    login_cmd = (f"echo 'y' | argocd login {SERVER_IP} "
                 f"--username admin --password '{NEW_PASSWORD}' --insecure")
    
    login_result = run_command(login_cmd)
    if login_result:
        print("🎉 SUCCESS: Logged into Argo CD successfully!")
        print(login_result)
    else:
        print("❌ Login failed. Check if the pod is fully 'Ready' (1/1).")

if __name__ == "__main__":
    main()