#!/usr/bin/env python3
import json
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

INTERFACE = "org.freedesktop.Notifications"
SIGNATURE = "(susssasa{sv}i)"
MAX_KEY = 128


def text(variant):
    if variant is None or variant.get_type_string() != "s":
        return ""
    value = variant.get_string()
    return value if len(value) <= MAX_KEY else ""


def on_message(connection, message, incoming):
    try:
        if message.get_interface() != INTERFACE or message.get_member() != "Notify":
            return message
        body = message.get_body()
        if body is None or body.get_type_string() != SIGNATURE:
            return None
        if body.get_child_value(1).get_uint32() != 0:
            return None
        update = {
            "app": text(body.get_child_value(0)),
            "entry": text(body.get_child_value(6).lookup_value("desktop-entry", None)),
        }
        if update["app"] or update["entry"]:
            print(json.dumps(update), flush=True)
    except Exception:
        pass
    return None


def main():
    address = Gio.dbus_address_get_for_bus_sync(Gio.BusType.SESSION, None)
    flags = Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION
    connection = Gio.DBusConnection.new_for_address_sync(address, flags, None, None)
    connection.add_filter(on_message)
    rule = "type='method_call',interface='%s',member='Notify'" % INTERFACE
    connection.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus.Monitoring",
                         "BecomeMonitor", GLib.Variant("(asu)", ([rule], 0)), None, Gio.DBusCallFlags.NONE, -1, None)
    GLib.MainLoop().run()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
