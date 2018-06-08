project('locale', 'vala', 'c')

gettext_name = meson.project_name() + '-plug'
gnome = import('gnome')
i18n = import('i18n')
pkg_data_dir = join_paths(switchboard_dep.get_pkgconfig_variable('plugsdir'), 'personal', 'pantheon-' + meson.project_name())


add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(gettext_name),
    '-DGNOME_DESKTOP_USE_UNSTABLE_API',
    language: 'c'
)

add_project_arguments(
    ['--vapidir', join_paths(meson.current_source_dir(), 'vapi')],
    language: 'vala'
)

configuration_data = configuration_data()
configuration_data.set('GETTEXT_PACKAGE', gettext_name)
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
