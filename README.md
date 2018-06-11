# Switchboard Locale Plug
[![l10n](https://l10n.elementary.io/widgets/switchboard/switchboard-plug-locale/svg-badge.svg)](https://l10n.elementary.io/projects/switchboard/switchboard-plug-locale)

## Building and Installation

You'll need the following dependencies:

* libaccountsservice-dev
* libibus-1.0-dev
* libgnome-desktop-3-dev
* libgranite-dev
* libswitchboard-2.0-dev
* meson >= 0.46.1
* policykit-1
* valac

Run `meson` to configure the build environment and then `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`

    sudo ninja install
