#!/usr/bin/env python3
import json
import os
import shlex
import sys
import xml.etree.ElementTree as ET
from urllib.parse import quote, unquote, urlparse

NS = "{http://www.freedesktop.org/standards/desktop-bookmarks}"
PER_PROGRAM = 5
MAX_PROGRAMS = 64
MAX_FILE_BYTES = 4 * 1024 * 1024
MAX_EXEC = 4096


def program(exec_line):
    if len(exec_line) > MAX_EXEC:
        return ""
    try:
        parts = shlex.split(exec_line)
        if len(parts) == 1:
            parts = shlex.split(parts[0])
    except ValueError:
        return ""
    return os.path.basename(parts[0]) if parts else ""


def main():
    try:
        if os.path.getsize(sys.argv[1]) > MAX_FILE_BYTES:
            raise OSError
        root = ET.parse(sys.argv[1]).getroot()
    except (ET.ParseError, OSError, IndexError):
        print("{}")
        return
    seen = []
    for bookmark in root.iter("bookmark"):
        url = urlparse(bookmark.get("href", ""))
        if url.scheme != "file":
            continue
        path = unquote(url.path)
        for app in bookmark.iter(NS + "application"):
            name = program(app.get("exec", ""))
            if name and name != "gio":
                seen.append((app.get("modified", ""), name, path))
    seen.sort(reverse=True)
    out = {}
    for _, name, path in seen:
        uri = "file://" + quote(path)
        files = out.get(name)
        if files is None:
            if len(out) >= MAX_PROGRAMS:
                continue
            files = out[name] = []
        if len(files) >= PER_PROGRAM or any(f["uri"] == uri for f in files) or not os.path.exists(path):
            continue
        files.append({"uri": uri, "name": os.path.basename(path), "folder": os.path.basename(os.path.dirname(path))})
    for files in out.values():
        names = [f["name"] for f in files]
        for f in files:
            label = f["name"] if names.count(f["name"]) == 1 else "%s (%s)" % (f["name"], f.pop("folder"))
            f.pop("folder", None)
            f["name"] = label
    print(json.dumps(out))


if __name__ == "__main__":
    main()
