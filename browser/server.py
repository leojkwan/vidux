#!/usr/bin/env python3
"""
vidux browser — localhost web UI for viewing PLAN.md across the fleet.

Read-only viewer. Stdlib only. See projects/vidux-browser/PLAN.md.
"""

from __future__ import annotations

import json
import os
import re
import sys
import time
from glob import glob
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

DEV_ROOT = Path(os.environ.get("VIDUX_DEV_ROOT", Path.home() / "Development"))
HOST = "127.0.0.1"
PORT = int(os.environ.get("VIDUX_BROWSER_PORT", "7191"))

BROWSER_DIR = Path(__file__).resolve().parent
STATIC_DIR = BROWSER_DIR / "static"

# Three known plan-layout conventions in Leo's fleet.
PLAN_GLOBS = [
    "*/ai/plans/*/PLAN.md",
    "*/vidux/*/PLAN.md",
    "*/projects/*/PLAN.md",
    "*/PLAN.md",
]

# Files to expose alongside PLAN.md when present.
SIBLING_FILES = ["PROGRESS.md", "INBOX.md", "ASK-LEO.md", "DOCTRINE.md", "README.md"]

HOT_DAYS = 7
STALE_DAYS = 30


def discover_plans() -> list[dict]:
    """Walk DEV_ROOT and return one entry per PLAN.md found."""
    seen: set[Path] = set()
    plans: list[dict] = []
    for pattern in PLAN_GLOBS:
        for hit in glob(str(DEV_ROOT / pattern)):
            path = Path(hit).resolve()
            if path in seen:
                continue
            if "node_modules" in path.parts:
                continue
            seen.add(path)
            plans.append(plan_meta(path))
    plans.sort(key=lambda p: (-p["mtime"], p["repo"], p["slug"]))
    return plans


def plan_meta(path: Path) -> dict:
    rel = path.relative_to(DEV_ROOT)
    parts = rel.parts
    repo = parts[0]
    # Slug is the directory name containing PLAN.md, or "_root_" for repo-root plans.
    parent_dir = path.parent
    if parent_dir == DEV_ROOT / repo:
        slug = "_root_"
    else:
        slug = parent_dir.name
    mtime = path.stat().st_mtime
    age_days = (time.time() - mtime) / 86400
    if age_days <= HOT_DAYS:
        status = "hot"
    elif age_days <= STALE_DAYS:
        status = "stale"
    else:
        status = "cold"
    siblings = [f for f in SIBLING_FILES if (parent_dir / f).is_file()]
    purpose = extract_purpose(path)
    return {
        "repo": repo,
        "slug": slug,
        "path": str(path),
        "rel": str(rel),
        "size": path.stat().st_size,
        "mtime": mtime,
        "age_days": round(age_days, 1),
        "status": status,
        "siblings": siblings,
        "purpose": purpose,
    }


def extract_purpose(path: Path) -> str:
    """Pull the first non-heading paragraph under '## Purpose' for sidebar preview."""
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""
    m = re.search(r"##\s+Purpose\s*\n+([^\n#].+?)(?=\n\s*\n|\n##|\Z)", text, re.S)
    if not m:
        # Fall back to first non-heading paragraph after the title.
        m = re.search(r"^#[^\n]*\n+([^\n#].+?)(?=\n\s*\n|\n##|\Z)", text, re.S | re.M)
    if not m:
        return ""
    return re.sub(r"\s+", " ", m.group(1)).strip()[:240]


def safe_resolve(raw: str) -> Path | None:
    """Only allow paths under DEV_ROOT — read-only contract is load-bearing."""
    try:
        p = Path(raw).resolve()
    except (OSError, ValueError):
        return None
    try:
        p.relative_to(DEV_ROOT)
    except ValueError:
        return None
    if not p.is_file():
        return None
    return p


class Handler(BaseHTTPRequestHandler):
    server_version = "viduxBrowser/0.1"

    def log_message(self, fmt, *args):  # noqa: N802 — stdlib override
        sys.stderr.write(f"[{self.log_date_time_string()}] {fmt % args}\n")

    def do_GET(self):  # noqa: N802 — stdlib override
        url = urlparse(self.path)
        route = url.path
        qs = parse_qs(url.query)
        if route == "/" or route == "/index.html":
            self._serve_static("index.html", "text/html; charset=utf-8")
        elif route.startswith("/static/"):
            name = route[len("/static/"):]
            if "/" in name or ".." in name:
                self._send(404, "not found")
                return
            ctype = guess_content_type(name)
            self._serve_static(name, ctype)
        elif route == "/api/health":
            self._json({"ok": True, "dev_root": str(DEV_ROOT), "port": PORT})
        elif route == "/api/plans":
            self._json({"plans": discover_plans(), "dev_root": str(DEV_ROOT)})
        elif route == "/api/file":
            raw = (qs.get("path") or [""])[0]
            p = safe_resolve(raw)
            if not p:
                self._send(403, "forbidden")
                return
            self._send_text(p.read_text(encoding="utf-8", errors="replace"))
        else:
            self._send(404, "not found")

    def _serve_static(self, name: str, ctype: str):
        path = STATIC_DIR / name
        if not path.is_file():
            self._send(404, f"static asset missing: {name}")
            return
        body = path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, payload):
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(body)

    def _send_text(self, text: str):
        body = text.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/markdown; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(body)

    def _send(self, code: int, msg: str):
        body = msg.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def guess_content_type(name: str) -> str:
    if name.endswith(".html"):
        return "text/html; charset=utf-8"
    if name.endswith(".css"):
        return "text/css; charset=utf-8"
    if name.endswith(".js"):
        return "application/javascript; charset=utf-8"
    if name.endswith(".json"):
        return "application/json; charset=utf-8"
    if name.endswith(".svg"):
        return "image/svg+xml"
    return "application/octet-stream"


def main():
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    url = f"http://{HOST}:{PORT}"
    sys.stderr.write(f"vidux browser → {url}  (dev_root={DEV_ROOT})\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        sys.stderr.write("\nstopped\n")
        server.server_close()


if __name__ == "__main__":
    main()
