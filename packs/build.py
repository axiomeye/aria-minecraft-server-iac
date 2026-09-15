"""Generate packwiz packs for the aria minecraft worlds from the Modrinth API.

packwiz has no tagged releases and there is no Go toolchain here, so the pack
files are emitted directly. Format reference: packwiz.infra.link/reference/pack-format.
Required dependencies are resolved recursively so the curated lists below only
need to name top-level mods.

Every resolved build is pinned in lock.json, so rebuilding reproduces the pack
byte for byte instead of silently adopting whatever Modrinth published since.
That silent drift is not hypothetical: it is how Cobblemon Raid Dens -- whose
newest build predates Cobblemon 1.8 and calls a Showdown method that release
removed -- reached the server and killed it at datapack load. Bump on purpose:

    python build.py                       # honour the lock
    python build.py --update              # re-resolve everything to newest
    python build.py --update lithium jei  # re-resolve only these

A mod dropped from the curated lists also drops out of the lock, since the lock
is rebuilt from what the lists actually resolve to.
"""
import hashlib, json, os, sys, urllib.request, urllib.parse

UA = {"User-Agent": "aria-minecraft-server-iac/1.0 (pack builder)"}
# Packs are written next to this script (packs/<world>/), not into a subdir.
OUT_ROOT = os.path.dirname(os.path.abspath(__file__))
LOCK_PATH = os.path.join(OUT_ROOT, "lock.json")


def api(path):
    return json.load(urllib.request.urlopen(
        urllib.request.Request("https://api.modrinth.com/v2" + path, headers=UA)))


_proj_cache = {}


def project(slug):
    if slug not in _proj_cache:
        _proj_cache[slug] = api("/project/" + slug)
    return _proj_cache[slug]


def resolve_slug(name):
    """Try the name as a slug; fall back to search."""
    try:
        return project(name)["slug"]
    except Exception:
        pass
    facets = '[["categories:fabric"],["project_type:mod"]]'
    hits = api("/search?query=" + urllib.parse.quote(name) +
               "&facets=" + urllib.parse.quote(facets) + "&limit=5")["hits"]
    if not hits:
        raise SystemExit(f"cannot resolve mod name: {name!r}")
    return hits[0]["slug"]


def newest_version(slug, mc, loader="fabric"):
    vs = api(f"/project/{slug}/version?loaders=%5B%22{loader}%22%5D"
             f"&game_versions=%5B%22{urllib.parse.quote(mc)}%22%5D")
    if not vs:
        return None
    # prefer a release over beta/alpha when one exists
    for want in ("release", "beta", "alpha"):
        for v in vs:
            if v["version_type"] == want:
                return v
    return vs[0]


def pinned_version(version_id):
    """Fetch one exact build by id. None if it is no longer on Modrinth."""
    try:
        return api("/version/" + version_id)
    except Exception:
        return None


def pick_version(slug, mc, lock, update, loader="fabric"):
    """The locked build if we have one, else the newest.

    Returns (version, is_fresh). is_fresh marks a build that was resolved now
    rather than taken from the lock, so the build log can show what moved.
    """
    pin = lock.get(slug)
    if pin and not ("*" in update or slug in update):
        v = pinned_version(pin)
        if v is not None:
            return v, False
        print(f"  !! {slug}: pinned build {pin} is gone from Modrinth - re-resolving")
    return newest_version(slug, mc, loader), True


def side_of(p):
    """Modrinth client_side/server_side -> packwiz side."""
    c, s = p.get("client_side"), p.get("server_side")
    if s == "unsupported":
        return "client"
    if c == "unsupported":
        return "server"
    return "both"


def primary_file(v):
    for f in v["files"]:
        if f.get("primary"):
            return f
    return v["files"][0]


def collect(names, mc, lock, update):
    """Resolve names + required deps -> ({slug: (project, version)}, ...).

    forced_both holds anything reached only as a *required* dependency of
    something in our list. Fabric Loader enforces a mod's declared `depends` on
    whichever side loads that mod, regardless of what the dependency's own
    Modrinth client_side/server_side fields claim about itself -- those describe
    whether the dependency is USEFUL standalone on a server, not whether the
    loader will tolerate its absence. Every top-level name we pass in here is
    server content, so any required dependency must load on the server too, or
    the server refuses to boot. (Found the hard way: CobbleFurnies requires
    Athena, whose own listing says server-unsupported; marking Athena
    client-only crashed the server with "which is missing!" at startup.)
    """
    out, queue, seen, forced_both = {}, [(n, False) for n in names], set(), set()
    new_lock, fresh = {}, {}
    while queue:
        name, is_dep = queue.pop(0)
        slug = resolve_slug(name)
        if is_dep:
            forced_both.add(slug)
        if slug in seen:
            continue
        seen.add(slug)
        v, is_fresh = pick_version(slug, mc, lock, update)
        if v is None:
            print(f"  !! {slug}: no fabric build for {mc} - SKIPPED")
            continue
        out[slug] = (project(slug), v)
        new_lock[slug] = v["id"]
        fresh[slug] = is_fresh
        for d in v.get("dependencies", []):
            if d.get("dependency_type") != "required":
                continue
            pid = d.get("project_id")
            if pid:
                try:
                    queue.append((project(pid)["slug"], True))
                except Exception:
                    print(f"  !! {slug}: unresolvable dependency {pid}")
    return out, forced_both, new_lock, fresh


def toml_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def build_client_extras(world, mc, slugs, lock, update):
    """Pin the client-only mods and write packs/<world>/client-extras.json.

    These stay out of the packwiz pack on purpose: the server neither needs nor
    installs them, and adding them would change the pack hash for no reason.
    Players get them from the Drive zip instead, so the manifest exists to make
    that zip rebuildable rather than a pile of hand-downloaded jars.

    Dependencies are deliberately NOT resolved here. This is a flat, curated
    list that mirrors a known-good install: the Iris build is paired with a
    specific Sodium build by hand after the two resolved independently to an
    incompatible pair, and anything these genuinely need (Fabric API) is already
    in the pack. Resolving transitively would re-introduce that pairing bug and
    duplicate pack mods into the client folder.
    """
    print(f"\n--- {world} client extras")
    manifest, new_lock = {}, {}
    for name in slugs:
        slug = resolve_slug(name)
        p = project(slug)
        # Resource packs are published under the "minecraft" loader, not
        # "fabric", and install into resourcepacks/ rather than mods/.
        is_pack = p["project_type"] == "resourcepack"
        loader = "minecraft" if is_pack else "fabric"
        v, is_fresh = pick_version(slug, mc, lock, update, loader)
        if v is None:
            print(f"  !! {slug}: no {loader} build for {mc} - SKIPPED")
            continue
        f = primary_file(v)
        new_lock[slug] = v["id"]
        manifest[slug] = {
            "dir": "resourcepacks" if is_pack else "mods",
            "name": p["title"],
            "filename": f["filename"],
            "url": f["url"],
            "sha512": f["hashes"]["sha512"],
            "version": v["version_number"],
        }
        mark = "*" if is_fresh else " "
        print(f" {mark} {p['title'][:38]:<40} {v['version_number'][:22]}")

    path = os.path.join(OUT_ROOT, world, "client-extras.json")
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(manifest, fh, indent=2, sort_keys=True)
        fh.write("\n")
    return new_lock


def build(world, mc, loader_version, names, lock, update):
    print(f"\n=== {world}  (Minecraft {mc})")
    resolved, forced_both, new_lock, fresh = collect(names, mc, lock, update)
    out_dir = os.path.join(OUT_ROOT, world)
    mods_dir = os.path.join(out_dir, "mods")
    os.makedirs(mods_dir, exist_ok=True)
    for f in os.listdir(mods_dir):
        os.remove(os.path.join(mods_dir, f))

    index_entries = []
    for slug in sorted(resolved):
        p, v = resolved[slug]
        f = primary_file(v)
        sha512 = f["hashes"]["sha512"]
        side = side_of(p)
        if side == "client" and slug in forced_both:
            print(f"  !! {p['title']}: Modrinth lists it client-only, but it's a "
                  f"required dependency here -- forcing side=both")
            side = "both"
        body = (
            f'name = "{toml_escape(p["title"])}"\n'
            f'filename = "{toml_escape(f["filename"])}"\n'
            f'side = "{side}"\n\n'
            "[download]\n"
            f'url = "{f["url"]}"\n'
            'hash-format = "sha512"\n'
            f'hash = "{sha512}"\n\n'
            "[update]\n"
            "[update.modrinth]\n"
            f'mod-id = "{p["id"]}"\n'
            f'version = "{v["id"]}"\n'
        )
        rel = f"mods/{slug}.pw.toml"
        path = os.path.join(out_dir, rel)
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(body)
        index_entries.append((rel, hashlib.sha256(body.encode()).hexdigest()))
        mark = "*" if fresh.get(slug) else " "
        print(f" {mark} {p['title'][:38]:<40} {v['version_number'][:22]:<24} {side}")

    index = 'hash-format = "sha256"\n\n' + "".join(
        f'[[files]]\nfile = "{rel}"\nhash = "{h}"\nmetafile = true\n\n'
        for rel, h in index_entries)
    with open(os.path.join(out_dir, "index.toml"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(index)

    pack = (
        f'name = "AriA {world.capitalize()}"\n'
        'author = "axiomeye"\n'
        'version = "1.0.0"\n'
        'pack-format = "packwiz:1.1.0"\n\n'
        "[index]\n"
        'file = "index.toml"\n'
        'hash-format = "sha256"\n'
        f'hash = "{hashlib.sha256(index.encode()).hexdigest()}"\n\n'
        "[versions]\n"
        f'minecraft = "{mc}"\n'
        f'fabric = "{loader_version}"\n'
    )
    with open(os.path.join(out_dir, "pack.toml"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(pack)

    sides = {}
    for slug in resolved:
        actual = "both" if (side_of(resolved[slug][0]) == "client" and slug in forced_both) else side_of(resolved[slug][0])
        sides[actual] = sides.get(actual, 0) + 1
    moved = sum(1 for s in fresh.values() if s)
    print(f"  -> {len(resolved)} mods  ({sides})"
          + (f"  [{moved} resolved fresh, marked *]" if moved else "  [all pinned]"))
    return new_lock


LATEST = ["lithium", "krypton", "clumps", "chunky", "terralith", "tectonic",
          "streams-reflowing", "fwa", "jei", "jade",
          "journeymap", "waystones", "easy-anvils", "travelersbackpack",
          "better-combat", "runes", "simple-voice-chat", "emotecraft",
          "skinrestorer", "easyauth"]

COBBLEMON = ["cobblemon", "cobbreeding", "rctmod", "cobblemon-mega-showdown",
             "cobblemon-fight-or-flight-reborn", "cobblemon-smartphone",
             "cobblemon-battle-tower", "cobblemon-cobblestats", "cobblemonextrastructures",
             "cobblemon-badgebox", "cobblefurnies",
             "cobblemon-environment-interactions", "cobblepedia",
             "catch-rate-display", "berry-pouch",
             "lithium", "krypton", "clumps",
             "jei", "jade", "journeymap", "waystones", "travelersbackpack",
             "trinkets", "easy-anvils", "double-doors", "cooking-for-blockheads", "treechop",
             "building-wands", "simple-voice-chat", "emotecraft", "skinrestorer", "easyauth"]

# Client-only quality-of-life mods. Not in the packwiz packs -- the server does
# not install them; they reach players through the Drive zip. Pinned all the
# same, so a local install can be rebuilt from scratch instead of re-downloaded
# by hand. See build_client_extras for why these are not dependency-resolved.
CLIENT_EXTRAS = {
    "latest": ["sodium", "iris", "modmenu", "lambdynamiclights", "betterf3",
               "explosive-enhancement", "voxy", "journeymap-web-map"],
    "cobblemon": ["sodium", "iris", "modmenu", "lambdynamiclights", "betterf3",
                  "explosive-enhancement", "noisium", "journeymap-web-map",
                  # Resource packs replacing vanilla music; no mod required.
                  "puffradio", "cobblemon-musicpack",
                  # Battle Tracks needs Cobblemon Intros for its non-looping intros.
                  "cobblemon-intros", "cobblemon-battle-tracks"],
}

WORLDS = [("latest", "26.2", LATEST), ("cobblemon", "1.21.1", COBBLEMON)]

if __name__ == "__main__":
    args = sys.argv[1:]
    update = set()
    if "--update" in args:
        rest = [a for a in args[args.index("--update") + 1:] if not a.startswith("-")]
        update = set(rest) if rest else {"*"}
        print("updating:", " ".join(sorted(update)) if rest else "everything")

    lock = {}
    if os.path.exists(LOCK_PATH):
        # utf-8-sig: PowerShell's Set-Content -Encoding utf8 prepends a BOM,
        # which json.load rejects. Tolerate it so a hand-edit on Windows does
        # not break the build.
        with open(LOCK_PATH, encoding="utf-8-sig") as fh:
            lock = json.load(fh)
    worlds_lock = lock.get("worlds", {})
    extras_lock = lock.get("client-extras", {})

    loader = lock.get("fabric-loader")
    if not loader or "*" in update or "fabric-loader" in update:
        loader = json.load(urllib.request.urlopen(urllib.request.Request(
            "https://meta.fabricmc.net/v2/versions/loader", headers=UA)))[0]["version"]
    print("fabric loader:", loader)

    new_worlds, new_extras = {}, {}
    for world, mc, names in WORLDS:
        new_worlds[world] = build(world, mc, loader, names,
                                  worlds_lock.get(world, {}), update)
        new_extras[world] = build_client_extras(
            world, mc, CLIENT_EXTRAS.get(world, []),
            extras_lock.get(world, {}), update)

    with open(LOCK_PATH, "w", encoding="utf-8", newline="\n") as fh:
        json.dump({"fabric-loader": loader, "worlds": new_worlds,
                   "client-extras": new_extras}, fh, indent=2, sort_keys=True)
        fh.write("\n")
    total = sum(len(w) for w in new_worlds.values()) \
        + sum(len(w) for w in new_extras.values())
    print(f"\nlock.json: {total} pinned builds")
