
import requests

url = "http://localhost:8000/api/v1/auth/token"
data = {
    "username": "platform_admin",
    "password": "admin@123"
}
try:
    response = requests.post(url, data=data)
    token = response.json().get("access_token")
    print(f"Token: {token[:10]}...")

    dash_url = "http://localhost:8000/api/v1/reports/dashboard-summary"
    headers = {
        "Authorization": f"Bearer {token}",
        "X-Branch-Code": "B1" # Assuming B1 exists, or try to find one
    }
    
    # Try to find a real branch code first
    branches_url = "http://localhost:8000/api/v1/branches"
    b_res = requests.get(branches_url, headers={"Authorization": f"Bearer {token}"})
    branches = b_res.json()
    if branches:
        headers["X-Branch-Code"] = branches[0]["code"]
        print(f"Using branch: {branches[0]['code']}")

    print("Fetching dashboard...")
    res = requests.get(dash_url, headers=headers)
    print(f"Status: {res.status_code}")
    print(res.text)
except Exception as e:
    print(f"Error: {e}")
