import os
import json
import firebase_admin
from firebase_admin import credentials, firestore
import requests

def sync_reports():
    # 1. Initialize Firebase
    # We expect FIREBASE_SERVICE_ACCOUNT_JSON as an environment variable (GitHub Secret)
    service_account_info = json.loads(os.environ.get('FIREBASE_SERVICE_ACCOUNT_JSON'))
    cred = credentials.Certificate(service_account_info)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    # 2. Get GitHub info
    github_token = os.environ.get('GITHUB_TOKEN')
    repo_name = os.environ.get('GITHUB_REPOSITORY') # e.g. "tsotnek/fuelpriceapp"
    headers = {
        "Authorization": f"token {github_token}",
        "Accept": "application/vnd.github.v3+json"
    }

    # 3. Fetch unsynced reports
    reports_ref = db.collection('bug_reports')
    unsynced_reports = reports_ref.where('synced', '==', False).stream()

    for doc in unsynced_reports:
        report_data = doc.to_dict()
        report_id = doc.id
        
        title = report_data.get('title', 'No Title')
        description = report_data.get('description', 'No Description')
        user_id = report_data.get('userId', 'anonymous')
        device = report_data.get('deviceName', 'unknown')
        os_ver = report_data.get('osVersion', 'unknown')
        app_ver = report_data.get('appVersion', 'unknown')
        
        # Format the issue body
        body = f"""
## Bug Report Details
**User ID:** {user_id}
**Device:** {device}
**OS:** {os_ver}
**App Version:** {app_ver}

### Description
{description}
        """

        # 4. Create GitHub Issue
        issue_url = f"https://api.github.com/repos/{repo_name}/issues"
        issue_data = {
            "title": f"[App Report] {title}",
            "body": body,
            "labels": ["bug", "in-app-report"]
        }
        
        response = requests.post(issue_url, headers=headers, json=issue_data)
        
        if response.status_code == 201:
            print(f"Successfully synced report {report_id} to GitHub.")
            # 5. Mark as synced in Firestore
            reports_ref.document(report_id).update({'synced': True})
        else:
            print(f"Failed to sync report {report_id}. Status: {response.status_code}")
            print(response.text)

if __name__ == "__main__":
    if not os.environ.get('FIREBASE_SERVICE_ACCOUNT_JSON'):
        print("Error: FIREBASE_SERVICE_ACCOUNT_JSON not set.")
    elif not os.environ.get('GITHUB_TOKEN'):
        print("Error: GITHUB_TOKEN not set.")
    else:
        sync_reports()
