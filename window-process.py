#!/usr/bin/env python3
import json
import os
import re
import sys

AGENT_ASSETS = "/usr/share/omarchy/shell/plugins/agents/assets"
MAX_ENVIRON = 256 * 1024
NAME = re.compile(r"^[a-z0-9][a-z0-9._-]{0,63}$")


def steam_id(pid):
    try:
        with open(f"/proc/{pid}/environ", "rb") as handle:
            data = handle.read(MAX_ENVIRON)
    except OSError:
        return ""
    found = {}
    for item in data.split(b"\0"):
        key, _, value = item.partition(b"=")
        if key in (b"SteamAppId", b"SteamGameId") and value.isdigit() and len(value) <= 20:
            found[key] = value.decode()
    return found.get(b"SteamAppId") or found.get(b"SteamGameId") or ""


def children(pid):
    out = []
    try:
        tasks = os.listdir(f"/proc/{pid}/task")
    except OSError:
        return out
    for task in tasks[:64]:
        try:
            with open(f"/proc/{pid}/task/{task}/children") as handle:
                out.extend(handle.read(4096).split())
        except OSError:
            pass
    return out[:32]


def agent_icon(pid):
    for child in children(pid):
        try:
            with open(f"/proc/{child}/comm") as handle:
                name = handle.read(64).strip().lower()
        except OSError:
            continue
        if not NAME.match(name):
            continue
        path = os.path.join(AGENT_ASSETS, name + ".svg")
        if os.path.isfile(path):
            return path
    return ""


for arg in sys.argv[1:65]:
    if not arg.isdigit():
        continue
    print(json.dumps({"pid": int(arg), "steam": steam_id(arg), "agentIcon": agent_icon(arg)}))
