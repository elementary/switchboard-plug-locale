gettext_declaration = configure_file(
    configuration: configuration_data,
    input: 'io.elementary.switchboard.locale.policy.in',
    output: '@BASENAME@'
)

install_data(
    gettext_declaration,
    install_dir: join_paths(get_option('datadir'), 'polkit-1', 'actions')
)

install_data(
    'io.elementary.switchboard.locale.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

install_data(
    'languagelist',
    install_dir: pkg_data_dir
)
