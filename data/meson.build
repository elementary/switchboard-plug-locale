i18n.merge_file(
    input: 'locale.policy.in',
    output: meson.project_name() + '.policy',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: polkit_actiondir
)

i18n.merge_file(
    input: 'locale.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(datadir, 'metainfo')
)

install_data(
    'locale.gschema.xml',
    install_dir: join_paths(datadir, 'glib-2.0', 'schemas'),
    rename: meson.project_name() + '.gschema.xml'
)

install_data(
    'languagelist',
    'packages_blocklist',
    install_dir: pkgdatadir
)
