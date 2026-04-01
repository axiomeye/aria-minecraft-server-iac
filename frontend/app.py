import os
import random
import time
from functools import wraps

import jwt
import requests
from authlib.integrations.flask_client import OAuth
from flask import Flask, jsonify, redirect, render_template, session, url_for
from werkzeug.middleware.proxy_fix import ProxyFix
from google.cloud import compute_v1

PHRASES = [
    "Do not believe Mr Elon",
    "BASATO KING",
    "Cose da gamer",
    "now do classical gas",
    "TO THE MOOOOOOOON!",
    "Oh, mansui...",
    "I can't believe it's not Terraria",
    "PLAY TERRARRIA",
    "Cubic bliss...",
    "Pixel paradise...",
    "It's square time!",
    "Square up!",
    "Why is it always Minecraft?",
    "Everybody gangsta until I pop in with the Snowmen Liberation Army.",
    "Cubic!",
    "Stop leaving crafting tables around!",
    "Reuse your crafting tables!",
    "Memo: chicken farm far from the house.",
    "Rip DukeP00l...",
    "Reanimating Herobrine...",
    "Knitting sheeps...",
    "The Elden Eye always watches (o)",
    "d(0w0)b",
    "You're gonna gurgle mayonaise!",
    "Bust this mamajam!",
    "Minecraft is the only game you need.",
    "Tfarcenim yalp",
    "Minecraft dies at the end.",
    "Elden Ring is basically a Minecraftlike.",
    "Why not just play Terraria at this point?",
    "Why playing minecraft when Terraria is around?",
    "I mean who even cares about 3D anymore?",
    "Why is everyone so obsessed with 3D???",
    "We don't talk about Dragons here...",
    "That fucking Ice Dragon killed my cat!",
    "Ice and Fire was a mistake...",
    "NOT THE SIRENS AGAIN LET ME GO",
    "Michelangelo!",
    "Oh you don't have the right",
    "Glabella Sandwich edition",
    "KASE!",
    "Soreto you wanna be my friend?",
    "Chamber of infinite bullshit",
    "Now without lettuce",
    "MOOOOOOOOOOOOOOOOOOOOOOOOON",
    "Space Australia release",
    "Happy hour edition",
    "Home of the funky Gallo",
    "Oh, the misery!",
    "Bake bread, fuck bitches, repeat",
    "Prossima Arrokoth Annaloro",
    "Try finger but hole",
    "Jump required ahead",
]

PROJECT = os.environ["GCP_PROJECT"]
ZONE = os.environ["GCP_ZONE"]
INSTANCE_NAME = os.environ["INSTANCE_NAME"]
OAUTH_REDIRECT_URI = os.environ.get("OAUTH_REDIRECT_URI")
REPO_OWNER = os.environ.get("GITHUB_REPO_OWNER", "axiomeye")
REPO_NAME = os.environ.get("GITHUB_REPO_NAME", "aria-minecraft-server-iac")
GH_APP_ID = os.environ["GH_APP_ID"]
GH_APP_INSTALLATION_ID = os.environ["GH_APP_INSTALLATION_ID"]
GH_APP_PRIVATE_KEY = os.environ["GH_APP_PRIVATE_KEY"]
ALLOWED = {e.strip() for e in os.environ["ALLOWED_EMAILS"].split(",")}

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)
app.secret_key = os.environ["FLASK_SECRET_KEY"]

oauth = OAuth(app)
oauth.register(
    name="google",
    client_id=os.environ["GOOGLE_CLIENT_ID"],
    client_secret=os.environ["GOOGLE_CLIENT_SECRET"],
    server_metadata_url="https://accounts.google.com/.well-known/openid-configuration",
    client_kwargs={"scope": "openid email"},
)


def require_login(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if "email" not in session:
            return redirect(url_for("login"))
        if session["email"] not in ALLOWED:
            return "Access denied.", 403
        return f(*args, **kwargs)
    return wrapper


def server_status():
    try:
        inst = compute_v1.InstancesClient().get(project=PROJECT, zone=ZONE, instance=INSTANCE_NAME)
        ip = next(
            (ac.nat_i_p for ni in inst.network_interfaces for ac in ni.access_configs if ac.nat_i_p),
            None,
        )
        return inst.status.lower(), ip
    except Exception:
        return "stopped", None


def get_installation_token():
    now = int(time.time())
    app_jwt = jwt.encode(
        {"iat": now - 60, "exp": now + 540, "iss": GH_APP_ID},
        GH_APP_PRIVATE_KEY,
        algorithm="RS256",
    )
    resp = requests.post(
        f"https://api.github.com/app/installations/{GH_APP_INSTALLATION_ID}/access_tokens",
        headers={"Authorization": f"Bearer {app_jwt}", "Accept": "application/vnd.github+json"},
        timeout=10,
    )
    return resp.json()["token"]


def trigger(event_type):
    token = get_installation_token()
    requests.post(
        f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/dispatches",
        headers={"Authorization": f"Bearer {token}", "Accept": "application/vnd.github+json"},
        json={"event_type": event_type},
        timeout=10,
    )


@app.get("/")
@require_login
def index():
    status, ip = server_status()
    return render_template("index.html", status=status, ip=ip, user=session["email"], phrase=random.choice(PHRASES))


@app.get("/api/status")
@require_login
def api_status():
    status, ip = server_status()
    return jsonify({"status": status, "ip": ip})


@app.get("/login")
def login():
    redirect_uri = OAUTH_REDIRECT_URI or url_for("callback", _external=True)
    return oauth.google.authorize_redirect(redirect_uri)


@app.get("/auth/callback")
def callback():
    token = oauth.google.authorize_access_token()
    session["email"] = token["userinfo"]["email"]
    return redirect(url_for("index"))


@app.get("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.post("/action/<name>")
@require_login
def action(name):
    events = {"start": "create-infr", "stop": "destroy-infr"}
    if name in events:
        trigger(events[name])
    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
