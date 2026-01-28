#!/usr/bin/env python3
"""Check and sync ArgoCD applications"""
import subprocess
import json
import time

def run_cmd(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

def main():
    print("\n" + "="*70)
    print("🔍 ArgoCD Applications Health & Sync Status Check")
    print("="*70)
    
    # Get apps
    output, _ = run_cmd("kubectl get applications -n argocd -o json")
    apps = json.loads(output)['items']
    app_names = [a['metadata']['name'] for a in apps]
    
    print(f"\n📦 Found {len(app_names)} applications: {', '.join(app_names)}\n")
    
    # Initial check
    print("INITIAL STATUS:")
    print("-"*70)
    statuses = {}
    for app_name in app_names:
        output, _ = run_cmd(f"kubectl get application {app_name} -n argocd -o json")
        app = json.loads(output)
        sync = app['status']['sync']['status']
        health = app['status']['health']['status']
        statuses[app_name] = {'sync': sync, 'health': health}
        h_icon = "✅" if health == 'Healthy' else "⚠️"
        s_icon = "✅" if sync == 'Synced' else "⏳"
        print(f"{h_icon} {app_name:20} | Health: {health:12} | Sync: {sync:12} {s_icon}")
    
    # Sync unsync'd apps
    unsync = [n for n, s in statuses.items() if s['sync'] != 'Synced']
    if unsync:
        print(f"\n🔄 Syncing {len(unsync)} applications...")
        print("-"*70)
        for app_name in unsync:
            print(f"  → {app_name}")
            patch = '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
            run_cmd(f"kubectl patch application {app_name} -n argocd --type merge -p '{patch}'")
    
    # Wait for sync
    print(f"\n⏳ Waiting 25 seconds for sync to complete...")
    for i in range(25, 0, -1):
        print(f"   {i}s remaining...", end='\r')
        time.sleep(1)
    print("                          ")
    
    # Final check
    print("\nFINAL STATUS:")
    print("-"*70)
    all_good = True
    for app_name in app_names:
        output, _ = run_cmd(f"kubectl get application {app_name} -n argocd -o json")
        app = json.loads(output)
        sync = app['status']['sync']['status']
        health = app['status']['health']['status']
        h_icon = "✅" if health == 'Healthy' else "❌"
        s_icon = "✅" if sync == 'Synced' else "❌"
        print(f"{h_icon} {app_name:20} | Health: {health:12} | Sync: {sync:12} {s_icon}")
        if health != 'Healthy' or sync != 'Synced':
            all_good = False
    
    # Summary
    print("\n" + "="*70)
    if all_good:
        print("✅ SUCCESS: ALL APPLICATIONS ARE HEALTHY AND SYNCED!")
    else:
        print("⚠️  Some applications need attention. Check status above.")
    print("="*70 + "\n")

if __name__ == '__main__':
    main()
