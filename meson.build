project(
    'locale-plug',
    'vala', 'c',
    meson_version: '>= 0.46.1',
    version: '2.4.1'
)

gnome = import('gnome')
i18n = import('i18n')
switchboard_dep = dependency('switchboard-2.0')
pkg_data_dir = join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'personal', 'pantheon-locale')


add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DGNOME_DESKTOP_USE_UNSTABLE_API',
    language: 'c'
)

add_project_arguments(
    ['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
    language: 'vala'
)

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', meson.project_name())
configuration_data.set('PKGDATADIR', pkg_data_dir)

constants = configure_file(
    configuration: configuration_data,
    input: 'config.vala.in',
    output: '@BASENAME@'
)

subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('meson/post_install.py')
