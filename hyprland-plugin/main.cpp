#include <format>
#include <vector>

#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/managers/EventManager.hpp>

#define private public
#include <hyprland/src/protocols/XDGShell.hpp>
#undef private

namespace {
    struct SWatch {
        WP<CXDGToplevelResource> toplevel;
        CHyprSignalListener      stateChanged;
    };

    CHyprSignalListener windowCreated;
    std::vector<SWatch> watches;

    void advertiseMinimize(CXDGToplevelResource* toplevel) {
        if (toplevel->m_resource->version() < 5)
            return;
        wl_array caps;
        wl_array_init(&caps);
        for (auto cap : {XDG_TOPLEVEL_WM_CAPABILITIES_FULLSCREEN, XDG_TOPLEVEL_WM_CAPABILITIES_MAXIMIZE, XDG_TOPLEVEL_WM_CAPABILITIES_MINIMIZE})
            *static_cast<uint32_t*>(wl_array_add(&caps, sizeof(uint32_t))) = cap;
        toplevel->m_resource->sendWmCapabilities(&caps);
        wl_array_release(&caps);
    }

    void watch(PHLWINDOW window, bool alreadyMapped) {
        std::erase_if(watches, [](const SWatch& w) { return w.toplevel.expired(); });
        if (!window || !window->m_xdgSurface || !window->m_xdgSurface->m_toplevel)
            return;
        auto toplevel = window->m_xdgSurface->m_toplevel.lock();
        auto raw      = toplevel.get();
        advertiseMinimize(raw);
        if (alreadyMapped)
            window->m_xdgSurface->scheduleConfigure();
        PHLWINDOWREF ref = window;
        watches.push_back({toplevel, toplevel->m_events.stateChanged.listen([raw, ref] {
                               if (!raw->m_state.requestsMinimize.value_or(false))
                                   return;
                               if (auto w = ref.lock())
                                   g_pEventManager->postEvent(SHyprIPCEvent{"minimized", std::format("{:x},1", reinterpret_cast<uintptr_t>(w.get()))});
                           })});
    }
}

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    windowCreated = Event::bus()->m_events.window.create.listen([](PHLWINDOW window) { watch(window, false); });
    for (const auto& window : Desktop::windowState()->windows())
        watch(window, true);
    return {"dockplus-minimize", "Sends the minimize button of Wayland apps to DockPlus", "gabrielsitta4", "1.0.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    windowCreated.reset();
    watches.clear();
}
