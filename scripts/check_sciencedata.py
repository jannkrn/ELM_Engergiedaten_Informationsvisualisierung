from __future__ import annotations

import base64
import json
import os
import urllib.request


BASE = "https://dbs.informatik.uni-halle.de/sciencedata"
SCHEMA = "energycharts"


def request_json(url: str, method: str = "GET", headers: dict[str, str] | None = None, body: dict | None = None):
    payload = b"" if method == "POST" and body is None else None
    if body is not None:
        payload = json.dumps(body).encode("utf-8")
    request = urllib.request.Request(url, data=payload, method=method, headers=headers or {})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def main() -> None:
    username = os.environ.get("ENERGYCHARTS_USER")
    password = os.environ.get("ENERGYCHARTS_PASSWORD")
    if not username or not password:
        raise SystemExit("ENERGYCHARTS_USER und ENERGYCHARTS_PASSWORD müssen gesetzt sein.")

    basic = base64.b64encode(f"{username}:{password}".encode()).decode()
    token_response = request_json(f"{BASE}/token", "POST", {"Authorization": f"Basic {basic}"})
    token = token_response["token"]
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept-Profile": SCHEMA,
        "Accept": "application/openapi+json",
    }
    specification = request_json(f"{BASE}/", headers=headers)
    paths = sorted(path for path in specification.get("paths", {}) if path != "/")
    result = {"base_url": BASE, "token_received": True, "resources": paths}

    table = os.environ.get("ENERGYCHARTS_TABLE")
    if table:
        table_headers = dict(headers)
        table_headers["Accept"] = "application/json"
        result["sample"] = request_json(f"{BASE}/{table}?limit=5", headers=table_headers)

    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
