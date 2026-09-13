"""Generate packwiz packs for the aria minecraft worlds from the Modrinth API.

packwiz has no tagged releases and there is no Go toolchain here, so the pack
files are emitted directly. Format reference: packwiz.infra.link/reference/pack-format.
Required dependencies are resolved recursively so the curated lists only need
to name top-level mods.
"""
import hashlib, json, os, sys, urllib.request, urllib.parse

UA = {"User-Agent": "aria-minecraft-server-iac/1.0 (pack builder)"}
# Packs are written next to this script (packs/<world>/), not into a subdir.
OUT_ROOT = os.path.dirname(os.path.abspath(__file__))


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


def newest_version(slug, mc):
    vs = api(f"/project/{slug}/version?loaders=%5B%22fabric%22%5D"
             f"&game_versions=%5B%22{urllib.parse.quote(mc)}%22%5D")
    if not vs:
        return None
    # prefer a release over beta/alpha when one exists
    for want in ("release", "beta", "alpha"):
        for v in vs:
            if v["version_type"] == want:
                return v
    return vs[0]


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


def collect(names, mc):
    """Resolve names + required deps -> {slug: (project, version, forced_both)}.

    forced_both is True for anything reached only as a *required* dependency
    of something in our list. Fabric Loader enforces a mod's declared
    `depends` on whichever side loads that mod, regardless of what the
    dependency's own Modrinth client_side/server_side fields claim about
    itself -- those describe whether the dependency is USEFUL standalone on
    a server, not whether the loader will tolerate its absence. Every
    top-level name we pass in here is server content, so any required
    dependency must load on the server too, or the server refuses to boot.
    (Found the hard way: CobbleFurnies requires Athena, whose own listing
    says server-unsupported; marking Athena client-only crashed the server
    with "which is missing!" at startup.)
    """
    out, queue, seen, forced_both = {}, [(n, False) for n in names], set(), set()
    while queue:
        name, is_dep = queue.pop(0)
        slug = resolve_slug(name)
        if is_dep:
            forced_both.add(slug)
        if slug in seen:
            continue
        seen.add(slug)
        v = newest_version(slug, mc)
        if v is None:
            print(f"  !! {slug}: no fabric build for {mc} - SKIPPED")
            continue
        out[slug] = (project(slug), v)
        for d in v.get("dependencies", []):
            if d.get("dependency_type") != "required":
                continue
            pid = d.get("project_id")
            if pid:
                try:
                    queue.append((project(pid)["slug"], True))
                except Exception:
                    print(f"  !! {slug}: unresolvable dependency {pid}")
    return out, forced_both


def toml_escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def build(world, mc, loader_version, names):
    print(f"\n=== {world}  (Minecraft {mc})")
    resolved, forced_both = collect(names, mc)
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
        print(f"  {p['title'][:38]:<40} {v['version_number'][:22]:<24} {side}")

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
    print(f"  -> {len(resolved)} mods  ({sides})")
    return len(resolved)


LATEST = ["lithium", "krypton", "clumps", "chunky", "terralith", "tectonic",
          "streams-reflowing", "fwa", "jei", "jade",
          "journeymap", "waystones", "easy-anvils", "travelersbackpack",
          "better-combat", "runes", "simple-voice-chat", "emotecraft",
          "skinrestorer", "easyauth"]

COBBLEMON = ["cobblemon", "cobbreeding", "rctmod", "cobblemon-mega-showdown",
             "cobblemon-fight-or-flight-reborn", "cobblemon-smartphone",
             "cobblemon-battle-tower", "cobblemon-cobblestats", "cobblemonextrastructures",
             "cobblemon-badgebox", "cobblefurnies",
             "cobblemon-environment-interactions", "cobblepedia", "cobblemonraiddens",
             "cobblemon-move-inspector", "catch-rate-display", "berry-pouch",
             "lithium", "krypton", "clumps",
             "jei", "jade", "journeymap", "waystones", "travelersbackpack",
             "trinkets", "easy-anvils", "double-doors", "cooking-for-blockheads", "treechop",
             "building-wands", "simple-voice-chat", "emotecraft", "skinrestorer", "easyauth"]

if __name__ == "__main__":
    loader = json.load(urllib.request.urlopen(urllib.request.Request(
        "https://meta.fabricmc.net/v2/versions/loader", headers=UA)))[0]["version"]
    print("fabric loader:", loader)
    build("latest", "26.2", loader, LATEST)
    build("cobblemon", "1.21.1", loader, COBBLEMON)
