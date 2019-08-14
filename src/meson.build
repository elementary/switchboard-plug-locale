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

#
# Define Vala minimal version
#
vala_version_required = '0.40.10'
vala_compiler = meson.get_compiler('vala')

if not vala_compiler.version().version_compare('>= @0@'.format(vala_version_required))
    error('Valac >= @0@ required!'.format(vala_version_required))
endif

shared_module(
    meson.project_name(),
    plug_files,
    constants,
    dependencies: [
        dependency('accountsservice'),
        dependency('glib-2.0'),
        dependency('gio-2.0'),
        dependency('gnome-desktop-3.0'),
        dependency('gobject-2.0'),
        dependency('granite'),
        dependency('gtk+-3.0'),
        dependency('ibus-1.0'),
        dependency('polkit-gobject-1'),
        vala_compiler.find_library('posix'),
        vala_compiler.find_library('monetary', dirs: join_paths(meson.source_root(), 'vapi')),
        switchboard_dep
    ],
    install: true,
    install_dir : join_paths(switchboard_plugsdir, 'personal')
)
