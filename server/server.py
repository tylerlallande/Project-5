"""Local BayouBlitz API. SQLite transactions own membership and deletion rules."""
import argparse
import hashlib
import json
import os
import secrets
import sqlite3
import uuid
from contextlib import contextmanager
from datetime import date
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


class ApiError(Exception):
    def __init__(self, status, message, code="error"):
        self.status, self.message, self.code = status, message, code


class Store:
    def __init__(self, path):
        self.path = str(path)
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as db:
            db.executescript("""
                PRAGMA journal_mode=WAL;
                CREATE TABLE IF NOT EXISTS sessions (
                    token_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL UNIQUE);
                CREATE TABLE IF NOT EXISTS tailgates (
                    id TEXT PRIMARY KEY, code TEXT NOT NULL UNIQUE,
                    host_id TEXT NOT NULL, draft TEXT NOT NULL,
                    is_public INTEGER NOT NULL CHECK (is_public IN (0,1)));
                CREATE TABLE IF NOT EXISTS members (
                    tailgate_id TEXT NOT NULL REFERENCES tailgates(id) ON DELETE CASCADE,
                    user_id TEXT NOT NULL, PRIMARY KEY(tailgate_id, user_id));
            """)

    @contextmanager
    def connect(self):
        db = sqlite3.connect(self.path, timeout=10)
        db.row_factory = sqlite3.Row
        db.execute("PRAGMA foreign_keys=ON")
        try:
            with db:
                yield db
        finally:
            db.close()

    def session(self):
        token, user = secrets.token_urlsafe(32), str(uuid.uuid4())
        with self.connect() as db:
            db.execute("INSERT INTO sessions VALUES (?,?)", (hashlib.sha256(token.encode()).hexdigest(), user))
        return {"token": token}

    def user(self, token):
        with self.connect() as db:
            row = db.execute("SELECT user_id FROM sessions WHERE token_hash=?", (hashlib.sha256(token.encode()).hexdigest(),)).fetchone()
        if not row:
            raise ApiError(401, "Your device session is no longer valid. Reconnect to start a new session.")
        return row[0]

    @staticmethod
    def entry(db, row, user, reveal_code=False):
        joined = db.execute("SELECT 1 FROM members WHERE tailgate_id=? AND user_id=?", (row["id"], user)).fetchone() is not None
        count = db.execute("SELECT COUNT(*) FROM members WHERE tailgate_id=?", (row["id"],)).fetchone()[0]
        return {"id": row["id"], "draft": json.loads(row["draft"]),
                "code": row["code"] if joined or reveal_code else "",
                "joined": joined, "hosted": row["host_id"] == user,
                "memberCount": count}

    def list(self, user):
        with self.connect() as db:
            rows = db.execute("""SELECT t.* FROM tailgates t WHERE is_public=1 OR EXISTS
                (SELECT 1 FROM members m WHERE m.tailgate_id=t.id AND m.user_id=?) ORDER BY t.rowid""", (user,)).fetchall()
            return [self.entry(db, row, user) for row in rows]

    def lookup(self, user, code):
        with self.connect() as db:
            row = db.execute("SELECT * FROM tailgates WHERE code=?", (str(code).upper().strip(),)).fetchone()
            if not row:
                raise ApiError(404, "No tailgate found for that code")
            return self.entry(db, row, user, True)

    def create(self, user, draft):
        fields = ("game", "name", "date", "kickoff", "meetupTime", "location", "vibe")
        if not isinstance(draft, dict) or any(not isinstance(draft.get(k), str) or not draft[k].strip() or len(draft[k]) > 200 for k in fields):
            raise ApiError(400, "Complete all tailgate details (200 characters maximum per field).")
        try:
            date.fromisoformat(draft["date"][:10])
        except ValueError:
            raise ApiError(400, "Choose a valid date")
        if not isinstance(draft.get("isPublic", False), bool):
            raise ApiError(400, "Invalid public setting")
        draft = {k: draft[k].strip() for k in fields} | {"isPublic": draft.get("isPublic", False)}
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            code = "".join(secrets.choice("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") for _ in range(6))
            while db.execute("SELECT 1 FROM tailgates WHERE code=?", (code,)).fetchone():
                code = "".join(secrets.choice("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") for _ in range(6))
            ident = str(uuid.uuid4())
            db.execute("INSERT INTO tailgates VALUES (?,?,?,?,?)", (ident, code, user, json.dumps(draft), int(draft["isPublic"])))
            db.execute("INSERT INTO members VALUES (?,?)", (ident, user))
            return self.entry(db, db.execute("SELECT * FROM tailgates WHERE id=?", (ident,)).fetchone(), user)

    def join(self, user, ident, code):
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            row = db.execute("SELECT * FROM tailgates WHERE id=?", (ident,)).fetchone()
            if not row:
                raise ApiError(404, "This tailgate no longer exists.")
            member = db.execute("SELECT 1 FROM members WHERE tailgate_id=? AND user_id=?", (ident, user)).fetchone()
            if not row["is_public"] and not member and str(code).upper().strip() != row["code"]:
                raise ApiError(403, "An invite code is required for this private tailgate.")
            db.execute("INSERT OR IGNORE INTO members VALUES (?,?)", (ident, user))
            return self.entry(db, row, user)

    def leave(self, user, ident, confirm_delete=False):
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            row = db.execute("SELECT * FROM tailgates WHERE id=?", (ident,)).fetchone()
            if not row:
                raise ApiError(404, "This tailgate no longer exists.")
            if not db.execute("SELECT 1 FROM members WHERE tailgate_id=? AND user_id=?", (ident, user)).fetchone():
                raise ApiError(403, "You are not a member of this tailgate.")
            count = db.execute("SELECT COUNT(*) FROM members WHERE tailgate_id=?", (ident,)).fetchone()[0]
            if count == 1 and confirm_delete is not True:
                raise ApiError(409, "You’re the last member. Leaving will permanently delete this tailgate and its invite code.", "last_member")
            db.execute("DELETE FROM members WHERE tailgate_id=? AND user_id=?", (ident, user))
            if count == 1:
                db.execute("DELETE FROM tailgates WHERE id=?", (ident,))
            elif row["host_id"] == user:
                next_host = db.execute("SELECT user_id FROM members WHERE tailgate_id=? ORDER BY user_id LIMIT 1", (ident,)).fetchone()[0]
                db.execute("UPDATE tailgates SET host_id=? WHERE id=?", (next_host, ident))
            return {"deleted": count == 1}


def handler(store, allowed_origins=None):
    configured_origins = set(allowed_origins or ())

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass  # Do not log bearer credentials or invite codes.

        def origin_allowed(self):
            origin = self.headers.get("Origin")
            if not origin:
                return True
            parsed = urlparse(origin)
            is_local = parsed.scheme == "http" and parsed.hostname in ("127.0.0.1", "localhost")
            return is_local or origin in configured_origins

        def respond(self, status, data):
            raw = json.dumps(data).encode()
            self.send_response(status)
            if self.headers.get("Origin") and self.origin_allowed():
                self.send_header("Access-Control-Allow-Origin", self.headers["Origin"])
                self.send_header("Vary", "Origin")
            self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)

        def do_OPTIONS(self):
            self.respond(200 if self.origin_allowed() else 403, {})

        def do_GET(self):
            self.dispatch()

        def do_POST(self):
            self.dispatch()

        def dispatch(self):
            try:
                if not self.origin_allowed():
                    raise ApiError(403, "Origin not allowed")
                route = urlparse(self.path).path
                if self.command == "GET" and route == "/health":
                    return self.respond(200, {"status": "ok"})
                body = {}
                if self.command == "POST":
                    length = int(self.headers.get("Content-Length", 0))
                    if not 0 <= length <= 16384:
                        raise ApiError(413, "Request too large")
                    body = json.loads(self.rfile.read(length) or b"{}")
                    if not isinstance(body, dict):
                        raise ApiError(400, "Expected a JSON object")
                if self.command == "POST" and route == "/sessions":
                    return self.respond(201, store.session())
                auth = self.headers.get("Authorization", "")
                user = store.user(auth[7:] if auth.startswith("Bearer ") else "")
                if route == "/tailgates" and self.command == "GET":
                    return self.respond(200, store.list(user))
                if route == "/tailgates" and self.command == "POST":
                    return self.respond(201, store.create(user, body.get("draft")))
                if route == "/tailgates/lookup" and self.command == "POST":
                    return self.respond(200, store.lookup(user, body.get("code", "")))
                parts = route.strip("/").split("/")
                if self.command == "POST" and len(parts) == 3 and parts[0] == "tailgates":
                    if parts[2] == "join":
                        return self.respond(200, store.join(user, parts[1], body.get("code", "")))
                    if parts[2] == "leave":
                        return self.respond(200, store.leave(user, parts[1], body.get("confirmDelete", False)))
                raise ApiError(404, "Not found")
            except ApiError as error:
                self.respond(error.status, {"message": error.message, "code": error.code})
            except (ValueError, TypeError):
                self.respond(400, {"message": "Invalid request"})
            except Exception:
                self.respond(500, {"message": "The server could not complete this request."})
    return Handler


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default=os.environ.get("HOST", "0.0.0.0"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("PORT", "8080")))
    parser.add_argument("--db", default=os.environ.get(
        "DB_PATH", str(Path(__file__).parent / "data" / "tailgates.sqlite3")))
    parser.add_argument("--allowed-origins", default=os.environ.get("ALLOWED_ORIGINS", ""),
                        help="Comma-separated exact browser origins, such as https://app.example.com")
    args = parser.parse_args()
    origins = {origin.strip() for origin in args.allowed_origins.split(",") if origin.strip()}
    service = ThreadingHTTPServer((args.host, args.port), handler(Store(args.db), origins))
    print(f"BayouBlitz API listening on {args.host}:{args.port}; database: {args.db}", flush=True)
    service.serve_forever()
