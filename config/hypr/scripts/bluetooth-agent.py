#!/usr/bin/env python3
"""
Lightweight BlueZ Bluetooth Agent for Hyprland session.
Handles automatic authorization, PIN/Passkey confirmation,
ensures adapter is powered & pairable, and sends notifications.
"""

import sys
import os
import subprocess
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

AGENT_PATH = "/org/bluez/hyprland/agent"
CAPABILITY = "NoInputNoOutput"

def notify(summary, body="", icon="bluetooth"):
    try:
        subprocess.Popen(["notify-send", "-i", icon, summary, body],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def get_device_name(bus, device_path):
    try:
        props = dbus.Interface(bus.get_object("org.bluez", device_path), "org.freedesktop.DBus.Properties")
        return str(props.Get("org.bluez.Device1", "Alias"))
    except Exception:
        return "Bluetooth Device"

class BluezAgent(dbus.service.Object):
    def __init__(self, bus, path):
        super().__init__(bus, path)
        self.bus = bus

    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Release(self):
        pass

    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="")
    def AuthorizeService(self, device, uuid):
        dev_name = get_device_name(self.bus, device)
        # Auto-trust connected device so future connections don't require re-auth
        try:
            props = dbus.Interface(self.bus.get_object("org.bluez", device), "org.freedesktop.DBus.Properties")
            props.Set("org.bluez.Device1", "Trusted", dbus.Boolean(True))
        except Exception:
            pass
        return

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        dev_name = get_device_name(self.bus, device)
        notify("Bluetooth Pairing", f"Pairing PIN 0000 sent to {dev_name}")
        return "0000"

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        return dbus.UInt32(0)

    @dbus.service.method("org.bluez.Agent1", in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        dev_name = get_device_name(self.bus, device)
        notify("Bluetooth Passkey", f"{dev_name}: {passkey:06d}")

    @dbus.service.method("org.bluez.Agent1", in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        dev_name = get_device_name(self.bus, device)
        notify("Bluetooth Paired", f"Confirmed pairing with {dev_name}")
        # Mark trusted
        try:
            props = dbus.Interface(self.bus.get_object("org.bluez", device), "org.freedesktop.DBus.Properties")
            props.Set("org.bluez.Device1", "Trusted", dbus.Boolean(True))
        except Exception:
            pass
        return

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="")
    def RequestAuthorization(self, device):
        dev_name = get_device_name(self.bus, device)
        notify("Bluetooth Authorized", f"Authorized {dev_name}")
        return

    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Cancel(self):
        pass

def setup_adapters_and_agent(bus):
    try:
        manager_obj = bus.get_object("org.bluez", "/")
        om = dbus.Interface(manager_obj, "org.freedesktop.DBus.ObjectManager")
        objects = om.GetManagedObjects()
        adapters = [p for p, ifaces in objects.items() if "org.bluez.Adapter1" in ifaces]

        for adapter_path in adapters:
            props = dbus.Interface(bus.get_object("org.bluez", adapter_path), "org.freedesktop.DBus.Properties")
            props.Set("org.bluez.Adapter1", "Powered", dbus.Boolean(True))
            props.Set("org.bluez.Adapter1", "Pairable", dbus.Boolean(True))

        agent = BluezAgent(bus, AGENT_PATH)
        agent_manager = dbus.Interface(bus.get_object("org.bluez", "/org/bluez"), "org.bluez.AgentManager1")
        try:
            agent_manager.UnregisterAgent(AGENT_PATH)
        except Exception:
            pass
        agent_manager.RegisterAgent(AGENT_PATH, CAPABILITY)
        agent_manager.RequestDefaultAgent(AGENT_PATH)
        return agent
    except Exception as e:
        print(f"Error setting up agent: {e}", file=sys.stderr)
        return None

def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    loop = GLib.MainLoop()
    agent = setup_adapters_and_agent(bus)

    # Listen for bluez restarts
    def name_owner_changed(name, old_owner, new_owner):
        nonlocal agent
        if name == "org.bluez" and new_owner:
            agent = setup_adapters_and_agent(bus)

    bus.add_signal_receiver(
        name_owner_changed,
        signal_name="NameOwnerChanged",
        dbus_interface="org.freedesktop.DBus"
    )

    try:
        loop.run()
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    main()
