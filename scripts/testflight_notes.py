#!/usr/bin/env python3
"""Set the TestFlight "What to Test" notes for a build, via the App Store Connect API.

    testflight_notes.py <bundleId> <buildNumber> <notes-file> [locale]

Waits for the build to finish processing, then creates or updates the
localisation. Locale defaults to ru.

Needs PyJWT. The system python on the build mac is PEP 668-managed, so install
into a venv rather than fighting it:

    python3 -m venv /tmp/tfvenv && /tmp/tfvenv/bin/pip install pyjwt cryptography
    /tmp/tfvenv/bin/python scripts/testflight_notes.py io.talerid.app 223 notes.txt

Lived in /tmp on the build mac until 2026-08-03, where it did not survive
reboots and had the notes text baked into it.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt  # PyJWT

KEY_ID = os.environ.get("ASC_KEY_ID", "J3P22V4URD")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "44b87272-3052-40ea-a48a-6c6f88a2df11")
KEY_PATH = os.environ.get(
    "ASC_KEY_PATH",
    os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8"),
)
BASE = "https://api.appstoreconnect.apple.com/v1"

POLL_ATTEMPTS = 30
POLL_SECONDS = 30


def token() -> str:
    with open(KEY_PATH) as fh:
        private_key = fh.read()
    return jwt.encode(
        {
            "iss": ISSUER_ID,
            "iat": int(time.time()),
            "exp": int(time.time()) + 900,
            "aud": "appstoreconnect-v1",
        },
        private_key,
        algorithm="ES256",
        # `typ` is required: without it the API answers 401, even though the
        # same key uploads fine through altool.
        headers={"alg": "ES256", "kid": KEY_ID, "typ": "JWT"},
    )


def call(method: str, path: str, body=None):
    url = path if path.startswith("http") else f"{BASE}{path}"
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, method=method)
    # A fresh token per request: reusing one across the polling loop came back
    # as intermittent 401s.
    req.add_header("Authorization", f"Bearer {token()}")
    if body:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as err:
        print(f"  HTTP {err.code} on {method} {url}\n  {err.read().decode()[:300]}")
        return None


def main() -> int:
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    bundle_id, build_number, notes_path = sys.argv[1], sys.argv[2], sys.argv[3]
    locale = sys.argv[4] if len(sys.argv) > 4 else "ru"

    with open(notes_path) as fh:
        notes = fh.read().strip()
    if not notes:
        print(f"{notes_path} is empty — refusing to publish a build with no notes")
        return 2

    # filter[bundleId] matches by prefix, so asking for tirol.taler.talerIdMobile
    # hands back tirol.taler.talerIdMobile.dev — which is how the TEST release
    # notes once landed on the DEV app while TEST got none (2026-08-03). Take the
    # exact match or nothing.
    apps = call("GET", "/apps?" + urllib.parse.urlencode({"filter[bundleId]": bundle_id}))
    app = next(
        (
            a
            for a in (apps or {}).get("data", [])
            if a["attributes"]["bundleId"] == bundle_id
        ),
        None,
    )
    if not app:
        returned = [a["attributes"]["bundleId"] for a in (apps or {}).get("data", [])]
        print(f"no app with bundleId exactly {bundle_id}; API returned {returned}")
        return 1
    app_id = app["id"]
    print(f"app: {app['attributes']['name']} ({app_id}) {app['attributes']['bundleId']}")

    build_id = None
    for attempt in range(POLL_ATTEMPTS):
        query = urllib.parse.urlencode(
            {
                "filter[app]": app_id,
                "filter[version]": build_number,
                "sort": "-uploadedDate",
                "limit": "5",
            }
        )
        builds = call("GET", f"/builds?{query}")
        if builds and builds.get("data"):
            build_id = builds["data"][0]["id"]
            state = builds["data"][0]["attributes"].get("processingState")
            print(f"build {build_number}: {build_id} ({state})")
            break
        print(f"  not visible yet, {attempt + 1}/{POLL_ATTEMPTS}")
        time.sleep(POLL_SECONDS)

    if not build_id:
        print("build never appeared — notes not set")
        return 1

    existing = call("GET", f"/builds/{build_id}/betaBuildLocalizations") or {}
    current = next(
        (x for x in existing.get("data", []) if x["attributes"]["locale"] == locale),
        None,
    )

    if current:
        out = call(
            "PATCH",
            f"/betaBuildLocalizations/{current['id']}",
            {
                "data": {
                    "type": "betaBuildLocalizations",
                    "id": current["id"],
                    "attributes": {"whatsNew": notes},
                }
            },
        )
        print("notes updated" if out is not None else "update failed")
    else:
        out = call(
            "POST",
            "/betaBuildLocalizations",
            {
                "data": {
                    "type": "betaBuildLocalizations",
                    "attributes": {"locale": locale, "whatsNew": notes},
                    "relationships": {
                        "build": {"data": {"type": "builds", "id": build_id}}
                    },
                }
            },
        )
        print("notes created" if out is not None else "create failed")

    return 0 if out is not None else 1


if __name__ == "__main__":
    sys.exit(main())
