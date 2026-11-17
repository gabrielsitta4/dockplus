CXXFLAGS ?= -O2
OUT ?= dockplus-minimize.so
HYPRLAND_VERSION := /usr/include/hyprland/src/version.h

$(OUT): main.cpp $(HYPRLAND_VERSION)
	$(CXX) -shared -fPIC -std=c++2b $(CXXFLAGS) $(shell pkg-config --cflags pixman-1 libdrm hyprland) $< -o $@

clean:
	rm -f $(OUT)

.PHONY: clean
