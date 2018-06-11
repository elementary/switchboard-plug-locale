gettext_declaration = configure_file(
    configuration: configuration_data,
    input: 'io.elementary.switchboard.locale.policy.in.in',
    output: '@BASENAME@'
)

i18n.merge_file(
    input: gettext_declaration,
    output: 'io.elementary.switchboard.locale.policy',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'polkit-1', 'actions')
)

i18n.merge_file(
    input: 'io.elementary.switchboard.locale.appdata.xml.in',
    output: '@BASENAME@',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
    'io.elementary.switchboard.locale.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

install_data(
    'languagelist',
    install_dir: pkg_data_dir
)
