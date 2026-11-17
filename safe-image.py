#!/usr/bin/env python3
import hashlib
import os
import resource
import sys
import urllib.parse
import urllib.request

MAX_BYTES = 32 * 1024 * 1024
MAX_URL = 128 * 1024
MAX_MEMORY = 1024 * 1024 * 1024
MAX_SECONDS = 10
MAX_FILES = 12
COVER_SIZE = 256
THUMB_SIZE = 256

resource.setrlimit(resource.RLIMIT_AS, (MAX_MEMORY, MAX_MEMORY))
resource.setrlimit(resource.RLIMIT_CPU, (MAX_SECONDS, MAX_SECONDS))

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf, GLib


def fit(width, height, size):
    scale = min(1.0, size / max(1, width, height))
    return max(1, round(width * scale)), max(1, round(height * scale))


def decode(data, size):
    loader = GdkPixbuf.PixbufLoader()
    loader.connect("size-prepared", lambda item, width, height: item.set_size(*fit(width, height, size)))
    loader.write(data)
    loader.close()
    return loader.get_pixbuf()


def save(pixbuf, target, keys=None, values=None):
    partial = target + ".part"
    pixbuf.savev(partial, "png", keys or [], values or [])
    os.chmod(partial, 0o600)
    os.replace(partial, target)


def read_url(url):
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme == "file":
        with open(urllib.parse.unquote(parsed.path), "rb") as handle:
            return handle.read(MAX_BYTES + 1)
    if parsed.scheme in ("http", "https", "data"):
        with urllib.request.urlopen(url, timeout=5) as response:
            return response.read(MAX_BYTES + 1)
    return b""


def cover(url, folder):
    if len(url) > MAX_URL:
        return
    name = "cover-" + hashlib.md5(url.encode()).hexdigest() + ".png"
    target = os.path.join(folder, name)
    if not os.path.isfile(target):
        data = read_url(url)
        if not data or len(data) > MAX_BYTES:
            return
        pixbuf = decode(data, COVER_SIZE)
        if pixbuf is None:
            return
        os.makedirs(folder, exist_ok=True)
        save(pixbuf, target)
    for other in os.listdir(folder):
        if other.startswith("cover-") and other != name:
            os.remove(os.path.join(folder, other))
    print(target)


def thumbnail(path, folder):
    info = os.stat(path)
    if not os.path.isfile(path) or info.st_size == 0 or info.st_size > MAX_BYTES:
        return
    if GdkPixbuf.Pixbuf.get_file_info(path)[0] is None:
        return
    uri = GLib.filename_to_uri(path, None)
    target = os.path.join(folder, hashlib.md5(uri.encode()).hexdigest() + ".png")
    if os.path.isfile(target):
        return
    with open(path, "rb") as handle:
        pixbuf = decode(handle.read(MAX_BYTES), THUMB_SIZE)
    if pixbuf is None:
        return
    os.makedirs(folder, mode=0o700, exist_ok=True)
    save(pixbuf, target, ["tEXt::Thumb::URI", "tEXt::Thumb::MTime"], [uri, str(int(info.st_mtime))])


def main():
    if len(sys.argv) == 4 and sys.argv[1] == "cover":
        cover(sys.argv[2], sys.argv[3])
    elif len(sys.argv) >= 4 and sys.argv[1] == "thumbnails":
        for path in sys.argv[3:3 + MAX_FILES]:
            try:
                thumbnail(path, sys.argv[2])
            except Exception:
                pass


try:
    main()
except Exception:
    pass
