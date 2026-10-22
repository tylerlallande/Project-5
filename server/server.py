"""Local Tgate API. SQLite transactions own membership and deletion rules."""
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
from urllib.parse import parse_qs, urlencode, urlparse
from urllib.request import Request, urlopen


class ApiError(Exception):
    def __init__(self, status, message, code="error"):
        self.status, self.message, self.code = status, message, code


def fetch_json(url, headers=None):
    request = Request(url, headers=headers or {})
    with urlopen(request, timeout=8) as response:
        return json.load(response)


def _team_name(value):
    if isinstance(value, dict):
        return str(value.get("name", "")).strip()
    return str(value or "").strip()


def normalize_game(game, *, live=False):
    """Convert CFBD schedule and scoreboard objects into one app contract."""
    home = game.get("homeTeam")
    away = game.get("awayTeam")
    status = game.get("status")
    if not status:
        status = "completed" if game.get("completed") else "scheduled"
    venue = game.get("venue")
    return {
        "id": str(game.get("id", "")),
        "homeTeam": _team_name(home),
        "awayTeam": _team_name(away),
        "startDate": game.get("startDate"),
        "status": status,
        "homePoints": home.get("points") if isinstance(home, dict) else game.get("homePoints"),
        "awayPoints": away.get("points") if isinstance(away, dict) else game.get("awayPoints"),
        "venue": venue.get("name") if isinstance(venue, dict) else venue,
        "live": bool(live),
    }


def games_feed(query):
    key = os.environ.get("CFBD_API_KEY")
    if not key:
        return {"configured": False, "games": []}
    params = {
        "year": query.get("year", [str(date.today().year)])[0],
        "team": query.get("team", ["LSU"])[0],
    }
    games = fetch_json(
        "https://api.collegefootballdata.com/games?" + urlencode(params),
        {"Authorization": f"Bearer {key}"},
    )
    return {"configured": True, "games": [normalize_game(game) for game in games]}


def scoreboard_feed(query):
    key = os.environ.get("CFBD_API_KEY")
    if not key:
        return {"configured": False, "games": []}
    params = {}
    classification = query.get("classification", [""])[0].strip()
    if classification:
        params["classification"] = classification
    url = "https://api.collegefootballdata.com/scoreboard"
    if params:
        url += "?" + urlencode(params)
    games = fetch_json(url, {"Authorization": f"Bearer {key}"})
    team = query.get("team", [""])[0].strip().casefold()
    if team:
        games = [game for game in games if team in {
            _team_name(game.get("homeTeam")).casefold(),
            _team_name(game.get("awayTeam")).casefold(),
        }]
    return {"configured": True, "games": [normalize_game(game, live=True) for game in games]}


def weather_feed(query):
    try:
        latitude = float(query["latitude"][0])
        longitude = float(query["longitude"][0])
    except (KeyError, ValueError, IndexError):
        raise ApiError(400, "Valid latitude and longitude are required.")
    params = urlencode({
        "latitude": latitude,
        "longitude": longitude,
        "current": "temperature_2m,precipitation,weather_code,wind_speed_10m",
        "hourly": "temperature_2m,precipitation_probability,weather_code,wind_speed_10m",
        "temperature_unit": "fahrenheit",
        "wind_speed_unit": "mph",
        "timezone": "UTC",
        "forecast_days": 7,
    })
    return fetch_json("https://api.open-meteo.com/v1/forecast?" + params)


class Store:
    def __init__(self, path):
        self.path = str(path)
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        with self.connect() as db:
            db.executescript("""
                PRAGMA journal_mode=WAL;
                CREATE TABLE IF NOT EXISTS sessions (
                    token_hash TEXT PRIMARY KEY, user_id TEXT NOT NULL UNIQUE,
                    display_name TEXT NOT NULL DEFAULT 'Tailgate member');
                CREATE TABLE IF NOT EXISTS accounts (
                    user_id TEXT PRIMARY KEY REFERENCES sessions(user_id) ON DELETE CASCADE,
                    email TEXT NOT NULL UNIQUE, password_hash TEXT NOT NULL,
                    password_salt TEXT NOT NULL);
                CREATE TABLE IF NOT EXISTS tailgates (
                    id TEXT PRIMARY KEY, code TEXT NOT NULL UNIQUE,
                    host_id TEXT NOT NULL, draft TEXT NOT NULL,
                    is_public INTEGER NOT NULL CHECK (is_public IN (0,1)));
                CREATE TABLE IF NOT EXISTS members (
                    tailgate_id TEXT NOT NULL REFERENCES tailgates(id) ON DELETE CASCADE,
                    user_id TEXT NOT NULL, PRIMARY KEY(tailgate_id, user_id));
                CREATE TABLE IF NOT EXISTS reports (
                    id TEXT PRIMARY KEY, tailgate_id TEXT NOT NULL,
                    reporter_id TEXT NOT NULL, reason TEXT NOT NULL,
                    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
                CREATE TABLE IF NOT EXISTS blocks (
                    blocker_id TEXT NOT NULL, blocked_host_id TEXT NOT NULL,
                    PRIMARY KEY(blocker_id, blocked_host_id));
                CREATE TABLE IF NOT EXISTS photos (
                    id TEXT PRIMARY KEY, tailgate_id TEXT NOT NULL REFERENCES tailgates(id) ON DELETE CASCADE,
                    user_id TEXT NOT NULL, url TEXT NOT NULL, caption TEXT NOT NULL,
                    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
                CREATE TABLE IF NOT EXISTS bring_items (
                    id TEXT PRIMARY KEY,
                    tailgate_id TEXT NOT NULL REFERENCES tailgates(id) ON DELETE CASCADE,
                    name TEXT NOT NULL, quantity INTEGER NOT NULL,
                    category TEXT NOT NULL, claimed_by TEXT,
                    is_packed INTEGER NOT NULL DEFAULT 0);
            """)
            self._add_column(db, "tailgates", "status", "TEXT NOT NULL DEFAULT 'upcoming'")
            self._add_column(db, "members", "status", "TEXT NOT NULL DEFAULT 'joined'")
            self._add_column(db, "members", "checked_in", "INTEGER NOT NULL DEFAULT 0")
            self._add_column(db, "sessions", "display_name", "TEXT NOT NULL DEFAULT 'Tailgate member'")

    @staticmethod
    def _add_column(db, table, column, declaration):
        columns = {row[1] for row in db.execute(f"PRAGMA table_info({table})")}
        if column not in columns:
            db.execute(f"ALTER TABLE {table} ADD COLUMN {column} {declaration}")

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

    @staticmethod
    def clean_display_name(display_name):
        value = str(display_name or "").strip()
        if not value or len(value) > 60:
            raise ApiError(400, "Enter a display name of 60 characters or fewer.")
        return value

    def session(self, display_name="Tailgate member"):
        display_name = self.clean_display_name(display_name)
        token, user = secrets.token_urlsafe(32), str(uuid.uuid4())
        with self.connect() as db:
            db.execute(
                "INSERT INTO sessions (token_hash,user_id,display_name) VALUES (?,?,?)",
                (hashlib.sha256(token.encode()).hexdigest(), user, display_name),
            )
        return {"token": token}

    def set_profile(self, user, display_name):
        display_name = self.clean_display_name(display_name)
        with self.connect() as db:
            result = db.execute(
                "UPDATE sessions SET display_name=? WHERE user_id=?",
                (display_name, user),
            )
            if result.rowcount != 1:
                raise ApiError(404, "Profile not found.")
        return {"displayName": display_name}

    def create_account(self, user, email, password):
        email = str(email or "").strip().casefold()
        password = str(password or "")
        if "@" not in email or len(email) > 254:
            raise ApiError(400, "Enter a valid email address.")
        if len(password) < 8 or len(password) > 128:
            raise ApiError(400, "Password must be between 8 and 128 characters.")
        salt = secrets.token_hex(16)
        password_hash = hashlib.pbkdf2_hmac(
            "sha256", password.encode(), bytes.fromhex(salt), 210000).hex()
        with self.connect() as db:
            try:
                db.execute("INSERT INTO accounts VALUES (?,?,?,?)",
                           (user, email, password_hash, salt))
            except sqlite3.IntegrityError:
                raise ApiError(409, "That email is already connected to an account.")
        return {"email": email, "saved": True}

    def user(self, token):
        with self.connect() as db:
            row = db.execute("SELECT user_id FROM sessions WHERE token_hash=?", (hashlib.sha256(token.encode()).hexdigest(),)).fetchone()
        if not row:
            raise ApiError(401, "Your device session is no longer valid. Reconnect to start a new session.")
        return row[0]

    @staticmethod
    def entry(db, row, user, reveal_code=False):
        member = db.execute("SELECT status FROM members WHERE tailgate_id=? AND user_id=?", (row["id"], user)).fetchone()
        membership = member[0] if member else "none"
        joined = membership == "joined"
        count = db.execute("SELECT COUNT(*) FROM members WHERE tailgate_id=? AND status='joined'", (row["id"],)).fetchone()[0]
        pending = db.execute("SELECT COUNT(*) FROM members WHERE tailgate_id=? AND status='pending'", (row["id"],)).fetchone()[0]
        waitlisted = db.execute("SELECT COUNT(*) FROM members WHERE tailgate_id=? AND status='waitlisted'", (row["id"],)).fetchone()[0]
        pending_members = []
        if row["host_id"] == user:
            pending_members = [item[0] for item in db.execute(
                "SELECT user_id FROM members WHERE tailgate_id=? AND status='pending' ORDER BY user_id",
                (row["id"],),
            ).fetchall()]
        members = []
        if joined:
            members = [dict(item) for item in db.execute(
                """SELECT m.user_id AS id, s.display_name AS displayName,
                    m.status, m.checked_in AS checkedIn,
                    CASE WHEN t.host_id=m.user_id THEN 1 ELSE 0 END AS isHost
                   FROM members m
                   JOIN sessions s ON s.user_id=m.user_id
                   JOIN tailgates t ON t.id=m.tailgate_id
                   WHERE m.tailgate_id=? AND m.status='joined'
                   ORDER BY isHost DESC, lower(s.display_name), m.user_id""",
                (row["id"],),
            ).fetchall()]
            for item in members:
                item["checkedIn"] = bool(item["checkedIn"])
                item["isHost"] = bool(item["isHost"])
        return {"id": row["id"], "draft": json.loads(row["draft"]),
                "code": row["code"] if joined or reveal_code else "",
                "joined": joined, "hosted": row["host_id"] == user,
                "memberCount": count, "membershipStatus": membership,
                "status": row["status"], "pendingCount": pending,
                "waitlistCount": waitlisted, "pendingMembers": pending_members,
                "members": members}

    def list(self, user):
        with self.connect() as db:
            rows = db.execute("""SELECT t.* FROM tailgates t WHERE
                (is_public=1 AND status != 'archived' AND NOT EXISTS
                    (SELECT 1 FROM blocks b WHERE b.blocker_id=? AND b.blocked_host_id=t.host_id))
                OR EXISTS (SELECT 1 FROM members m WHERE m.tailgate_id=t.id AND m.user_id=? AND m.status='joined')
                ORDER BY t.rowid""", (user, user)).fetchall()
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
        capacity = draft.get("capacity")
        if capacity is not None and (not isinstance(capacity, int) or capacity < 2 or capacity > 10000):
            raise ApiError(400, "Capacity must be between 2 and 10,000 guests.")
        requires_approval = draft.get("requiresApproval", False)
        if not isinstance(requires_approval, bool):
            raise ApiError(400, "Invalid approval setting")
        optional = {key: draft.get(key) for key in ("gameId", "latitude", "longitude")}
        draft = {k: draft[k].strip() for k in fields} | {
            "isPublic": draft.get("isPublic", False), "capacity": capacity,
            "requiresApproval": requires_approval, **optional}
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            duplicate = db.execute(
                "SELECT 1 FROM tailgates WHERE host_id=? AND lower(json_extract(draft, '$.game'))=lower(?) AND substr(json_extract(draft, '$.date'),1,10)=? AND status != 'archived'",
                (user, draft["game"], draft["date"][:10]),
            ).fetchone()
            if duplicate:
                raise ApiError(409, "You already have a tailgate for this game.", "duplicate_tailgate")
            code = "".join(secrets.choice("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") for _ in range(6))
            while db.execute("SELECT 1 FROM tailgates WHERE code=?", (code,)).fetchone():
                code = "".join(secrets.choice("ABCDEFGHJKLMNPQRSTUVWXYZ23456789") for _ in range(6))
            ident = str(uuid.uuid4())
            db.execute("INSERT INTO tailgates (id,code,host_id,draft,is_public,status) VALUES (?,?,?,?,?,'upcoming')", (ident, code, user, json.dumps(draft), int(draft["isPublic"])))
            db.execute("INSERT INTO members (tailgate_id,user_id,status) VALUES (?,?,'joined')", (ident, user))
            return self.entry(db, db.execute("SELECT * FROM tailgates WHERE id=?", (ident,)).fetchone(), user)

    def join(self, user, ident, code):
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            row = db.execute("SELECT * FROM tailgates WHERE id=?", (ident,)).fetchone()
            if not row:
                raise ApiError(404, "This tailgate no longer exists.")
            member = db.execute("SELECT status FROM members WHERE tailgate_id=? AND user_id=?", (ident, user)).fetchone()
            if not row["is_public"] and not member and str(code).upper().strip() != row["code"]:
                raise ApiError(403, "An invite code is required for this private tailgate.")
            if row["status"] in ("completed", "archived"):
                raise ApiError(409, "This tailgate is no longer accepting guests.")
            draft = json.loads(row["draft"])
            joined_count = db.execute("SELECT COUNT(*) FROM members WHERE tailgate_id=? AND status='joined'", (ident,)).fetchone()[0]
            capacity = draft.get("capacity")
            status = "waitlisted" if capacity and joined_count >= capacity else (
                "pending" if draft.get("requiresApproval") and row["host_id"] != user else "joined")
            db.execute("INSERT INTO members (tailgate_id,user_id,status) VALUES (?,?,?) ON CONFLICT(tailgate_id,user_id) DO UPDATE SET status=excluded.status", (ident, user, status))
            return self.entry(db, row, user)

    def leave(self, user, ident, confirm_delete=False):
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            row = db.execute("SELECT * FROM tailgates WHERE id=?", (ident,)).fetchone()
            if not row:
                raise ApiError(404, "This tailgate no longer exists.")
            if not db.execute("SELECT 1 FROM members WHERE tailgate_id=? AND user_id=?", (ident, user)).fetchone():
                raise ApiError(403, "You are not a member of this tailgate.")
            count = db.execute("SELECT COUNT(*) FROM members WHERE tailgate_id=? AND status='joined'", (ident,)).fetchone()[0]
            if count == 1 and confirm_delete is not True:
                raise ApiError(409, "You’re the last member. Leaving will permanently delete this tailgate and its invite code.", "last_member")
            db.execute("DELETE FROM members WHERE tailgate_id=? AND user_id=?", (ident, user))
            if count == 1:
                db.execute("DELETE FROM tailgates WHERE id=?", (ident,))
            else:
                if row["host_id"] == user:
                    next_host = db.execute("SELECT user_id FROM members WHERE tailgate_id=? AND status='joined' ORDER BY user_id LIMIT 1", (ident,)).fetchone()[0]
                    db.execute("UPDATE tailgates SET host_id=? WHERE id=?", (next_host, ident))
                next_waiting = db.execute("SELECT user_id FROM members WHERE tailgate_id=? AND status='waitlisted' ORDER BY user_id LIMIT 1", (ident,)).fetchone()
                if next_waiting:
                    db.execute("UPDATE members SET status='joined' WHERE tailgate_id=? AND user_id=?", (ident, next_waiting[0]))
            return {"deleted": count == 1}

    def set_status(self, user, ident, status):
        if status not in ("completed", "archived"):
            raise ApiError(400, "Invalid tailgate status")
        with self.connect() as db:
            row = db.execute("SELECT * FROM tailgates WHERE id=?", (ident,)).fetchone()
            if not row:
                raise ApiError(404, "This tailgate no longer exists.")
            if row["host_id"] != user:
                raise ApiError(403, "Only the host can change this tailgate.")
            db.execute("UPDATE tailgates SET status=? WHERE id=?", (status, ident))
            return self.entry(db, db.execute("SELECT * FROM tailgates WHERE id=?", (ident,)).fetchone(), user)

    def delete(self, user, ident):
        with self.connect() as db:
            row = db.execute("SELECT host_id,status FROM tailgates WHERE id=?", (ident,)).fetchone()
            if not row:
                raise ApiError(404, "This tailgate no longer exists.")
            if row["host_id"] != user:
                raise ApiError(403, "Only the host can delete this tailgate.")
            if row["status"] not in ("completed", "archived"):
                raise ApiError(409, "Complete or archive the tailgate before deleting it.")
            db.execute("DELETE FROM tailgates WHERE id=?", (ident,))
            return {"deleted": True}

    def approve(self, user, ident, member_id):
        with self.connect() as db:
            row = db.execute("SELECT * FROM tailgates WHERE id=?", (ident,)).fetchone()
            if not row or row["host_id"] != user:
                raise ApiError(403, "Only the host can approve guests.")
            draft = json.loads(row["draft"])
            joined_count = db.execute("SELECT COUNT(*) FROM members WHERE tailgate_id=? AND status='joined'", (ident,)).fetchone()[0]
            new_status = "waitlisted" if draft.get("capacity") and joined_count >= draft["capacity"] else "joined"
            result = db.execute("UPDATE members SET status=? WHERE tailgate_id=? AND user_id=? AND status='pending'", (new_status, ident, member_id))
            if result.rowcount != 1:
                raise ApiError(404, "Join request not found.")
            return self.entry(db, row, user)

    def reject(self, user, ident, member_id):
        with self.connect() as db:
            row = db.execute("SELECT * FROM tailgates WHERE id=?", (ident,)).fetchone()
            if not row or row["host_id"] != user:
                raise ApiError(403, "Only the host can reject guests.")
            result = db.execute("DELETE FROM members WHERE tailgate_id=? AND user_id=? AND status='pending'", (ident, member_id))
            if result.rowcount != 1:
                raise ApiError(404, "Join request not found.")
            return self.entry(db, row, user)

    def check_in(self, user, ident, checked_in):
        with self.connect() as db:
            result = db.execute("UPDATE members SET checked_in=? WHERE tailgate_id=? AND user_id=? AND status='joined'", (int(bool(checked_in)), ident, user))
            if result.rowcount != 1:
                raise ApiError(403, "Join this tailgate before checking in.")
            return {"checkedIn": bool(checked_in)}

    def report(self, user, ident, reason, block=False):
        reason = str(reason).strip()
        if not reason or len(reason) > 500:
            raise ApiError(400, "Give a report reason of 500 characters or less.")
        with self.connect() as db:
            row = db.execute("SELECT host_id FROM tailgates WHERE id=?", (ident,)).fetchone()
            if not row:
                raise ApiError(404, "This tailgate no longer exists.")
            if row["host_id"] == user:
                raise ApiError(400, "You cannot report your own tailgate.")
            db.execute("INSERT INTO reports (id,tailgate_id,reporter_id,reason) VALUES (?,?,?,?)", (str(uuid.uuid4()), ident, user, reason))
            if block:
                db.execute("INSERT OR IGNORE INTO blocks VALUES (?,?)", (user, row["host_id"]))
            return {"reported": True, "blocked": bool(block)}

    def photos(self, user, ident, url=None, caption=""):
        with self.connect() as db:
            member = db.execute("SELECT 1 FROM members WHERE tailgate_id=? AND user_id=? AND status='joined'", (ident, user)).fetchone()
            if not member:
                raise ApiError(403, "Join this tailgate to view its recap.")
            if url is not None:
                url, caption = str(url).strip(), str(caption).strip()
                if not url.startswith(("https://", "http://")) or len(url) > 2000 or len(caption) > 200:
                    raise ApiError(400, "Add a valid photo URL and a short caption.")
                db.execute("INSERT INTO photos (id,tailgate_id,user_id,url,caption) VALUES (?,?,?,?,?)", (str(uuid.uuid4()), ident, user, url, caption))
            return [dict(row) for row in db.execute("SELECT id,url,caption,created_at AS createdAt FROM photos WHERE tailgate_id=? ORDER BY created_at DESC", (ident,)).fetchall()]

    @staticmethod
    def _bring_item(db, ident, item_id):
        row = db.execute(
            """SELECT b.id,b.name,b.quantity,b.category,
               s.display_name AS claimedBy,b.is_packed AS isPacked
               FROM bring_items b LEFT JOIN sessions s ON s.user_id=b.claimed_by
               WHERE b.tailgate_id=? AND b.id=?""", (ident, item_id)).fetchone()
        if not row:
            raise ApiError(404, "Bring-list item not found.")
        item = dict(row)
        item["isPacked"] = bool(item["isPacked"])
        return item

    @staticmethod
    def _require_joined(db, user, ident):
        if not db.execute(
            "SELECT 1 FROM members WHERE tailgate_id=? AND user_id=? AND status='joined'",
            (ident, user)).fetchone():
            raise ApiError(403, "Join this tailgate to update its bring list.")

    def bring_items(self, user, ident):
        with self.connect() as db:
            self._require_joined(db, user, ident)
            ids = db.execute(
                "SELECT id FROM bring_items WHERE tailgate_id=? ORDER BY rowid", (ident,)).fetchall()
            return [self._bring_item(db, ident, row[0]) for row in ids]

    def add_bring_item(self, user, ident, data):
        name = str(data.get("name", "")).strip()
        quantity = data.get("quantity")
        category = data.get("category")
        if not name or len(name) > 100 or not isinstance(quantity, int) or not 1 <= quantity <= 999:
            raise ApiError(400, "Enter an item name and a quantity from 1 to 999.")
        if category not in ("food", "drinks", "gear", "games", "other"):
            raise ApiError(400, "Choose a valid item category.")
        item_id = str(uuid.uuid4())
        with self.connect() as db:
            self._require_joined(db, user, ident)
            db.execute("INSERT INTO bring_items VALUES (?,?,?,?,?,?,0)",
                       (item_id, ident, name, quantity, category, None))
            return self._bring_item(db, ident, item_id)

    def update_bring_item(self, user, ident, item_id, data):
        name = str(data.get("name", "")).strip()
        quantity, category = data.get("quantity"), data.get("category")
        if not name or len(name) > 100 or not isinstance(quantity, int) or not 1 <= quantity <= 999:
            raise ApiError(400, "Enter an item name and a quantity from 1 to 999.")
        if category not in ("food", "drinks", "gear", "games", "other"):
            raise ApiError(400, "Choose a valid item category.")
        with self.connect() as db:
            self._require_joined(db, user, ident)
            existing = db.execute("SELECT claimed_by FROM bring_items WHERE tailgate_id=? AND id=?", (ident, item_id)).fetchone()
            if not existing:
                raise ApiError(404, "Bring-list item not found.")
            claimed = user if data.get("claimedByMe") is True else (
                None if existing[0] == user else existing[0])
            packed = bool(data.get("isPacked")) if claimed == user else False
            db.execute("UPDATE bring_items SET name=?,quantity=?,category=?,claimed_by=?,is_packed=? WHERE tailgate_id=? AND id=?",
                       (name, quantity, category, claimed, int(packed), ident, item_id))
            return self._bring_item(db, ident, item_id)

    def delete_bring_item(self, user, ident, item_id):
        with self.connect() as db:
            self._require_joined(db, user, ident)
            result = db.execute("DELETE FROM bring_items WHERE tailgate_id=? AND id=?", (ident, item_id))
            if result.rowcount != 1:
                raise ApiError(404, "Bring-list item not found.")
            return {"deleted": True}


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
            return is_local or origin.rstrip("/") in configured_origins

        def respond(self, status, data):
            raw = json.dumps(data).encode()
            self.send_response(status)
            if self.headers.get("Origin") and self.origin_allowed():
                self.send_header("Access-Control-Allow-Origin", self.headers["Origin"])
                self.send_header("Vary", "Origin")
            self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
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

        def do_DELETE(self):
            self.dispatch()

        def dispatch(self):
            try:
                if not self.origin_allowed():
                    raise ApiError(403, "Origin not allowed")
                route = urlparse(self.path).path
                query = parse_qs(urlparse(self.path).query)
                if self.command == "GET" and route == "/health":
                    return self.respond(200, {"status": "ok"})
                if self.command == "GET" and route == "/games":
                    return self.respond(200, games_feed(query))
                if self.command == "GET" and route == "/scoreboard":
                    return self.respond(200, scoreboard_feed(query))
                if self.command == "GET" and route == "/weather":
                    return self.respond(200, weather_feed(query))
                body = {}
                if self.command == "POST":
                    length = int(self.headers.get("Content-Length", 0))
                    if not 0 <= length <= 16384:
                        raise ApiError(413, "Request too large")
                    body = json.loads(self.rfile.read(length) or b"{}")
                    if not isinstance(body, dict):
                        raise ApiError(400, "Expected a JSON object")
                if self.command == "POST" and route == "/sessions":
                    return self.respond(201, store.session(body.get("displayName", "Tailgate member")))
                auth = self.headers.get("Authorization", "")
                user = store.user(auth[7:] if auth.startswith("Bearer ") else "")
                if self.command == "POST" and route == "/profile":
                    return self.respond(200, store.set_profile(user, body.get("displayName")))
                if self.command == "POST" and route == "/account":
                    return self.respond(201, store.create_account(user, body.get("email"), body.get("password")))
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
                    if parts[2] in ("complete", "archive"):
                        status = "completed" if parts[2] == "complete" else "archived"
                        return self.respond(200, store.set_status(user, parts[1], status))
                    if parts[2] == "check-in":
                        return self.respond(200, store.check_in(user, parts[1], body.get("checkedIn", True)))
                    if parts[2] == "report":
                        return self.respond(200, store.report(user, parts[1], body.get("reason", ""), body.get("block", False)))
                    if parts[2] == "photos":
                        return self.respond(201, store.photos(user, parts[1], body.get("url"), body.get("caption", "")))
                if self.command == "GET" and len(parts) == 3 and parts[0] == "tailgates" and parts[2] == "photos":
                    return self.respond(200, store.photos(user, parts[1]))
                if len(parts) == 3 and parts[0] == "tailgates" and parts[2] == "bring-items":
                    if self.command == "GET":
                        return self.respond(200, store.bring_items(user, parts[1]))
                    if self.command == "POST":
                        return self.respond(201, store.add_bring_item(user, parts[1], body))
                if len(parts) == 4 and parts[0] == "tailgates" and parts[2] == "bring-items":
                    if self.command == "POST":
                        return self.respond(200, store.update_bring_item(user, parts[1], parts[3], body))
                    if self.command == "DELETE":
                        return self.respond(200, store.delete_bring_item(user, parts[1], parts[3]))
                if self.command == "POST" and len(parts) == 4 and parts[0] == "tailgates" and parts[2] == "approve":
                    return self.respond(200, store.approve(user, parts[1], parts[3]))
                if self.command == "POST" and len(parts) == 4 and parts[0] == "tailgates" and parts[2] == "reject":
                    return self.respond(200, store.reject(user, parts[1], parts[3]))
                if self.command == "DELETE" and len(parts) == 2 and parts[0] == "tailgates":
                    return self.respond(200, store.delete(user, parts[1]))
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
    parser.add_argument("--allowed-origins", default=os.environ.get(
        "ALLOWED_ORIGINS", os.environ.get("TAILGATE_ALLOWED_ORIGINS", "")),
                        help="Comma-separated exact browser origins, such as https://app.example.com")
    args = parser.parse_args()
    origins = {origin.strip().rstrip("/") for origin in args.allowed_origins.split(",") if origin.strip()}
    service = ThreadingHTTPServer((args.host, args.port), handler(Store(args.db), origins))
    print(f"Tgate API listening on {args.host}:{args.port}; database: {args.db}", flush=True)
    service.serve_forever()
