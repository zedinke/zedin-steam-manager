#!/usr/bin/env python3
import requests

try:
    response = requests.get("http://127.0.0.1:8005/api/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
except Exception as e:
    print(f"Error: {e}")