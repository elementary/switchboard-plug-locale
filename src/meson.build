plug_files = files(
    'Plug.vala',
    'Utils.vala',
    'LocaleManager.vala',
    'Installer/UbuntuInstaller.vala',
    'Installer/aptd-client.vala',
    'Widgets/InstallPopover.vala',
    'Widgets/InstallInfoBar.vala',
    'Widgets/LanguageListBox.vala',
    'Widgets/LocaleView.vala',
    'Widgets/LocaleSetting.vala',
    'Widgets/Preview.vala'
)

switchboard_dep = dependency('switchboard-2.0')

shared_module(
    meson.project_name(),
    plug_files,
    dependencies: [
        dependency('accountsservice'),
        dependency('glib-2.0'),
        dependency('gio-2.0'),
        dependency('gnome-desktop-3.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('ibus-1.0'),
        dependency('monetary'),
        dependency('polkit-agent-1'),
        meson.get_compiler('vala').find_library('posix'),
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'personal')
)