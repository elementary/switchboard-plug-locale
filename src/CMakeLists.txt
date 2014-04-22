find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0 switchboard-2.0 granite gnome-desktop-3.0 accountsservice)

add_definitions (${DEPS_CFLAGS} -DGNOME_DESKTOP_USE_UNSTABLE_API -w)
link_directories (${DEPS_LIBRARY_DIRS} /usr/share/polkit-1)

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.23.0" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C
    Plug.vala
    BaseEntry.vala
    LanguageList.vala
    LanguageEntry.vala
    LocaleManager.vala
    InstallEntry.vala
    InstallPopover.vala
    LanguageInstaller.vala
    Installer/UbuntuInstaller.vala
    Installer/aptd-client.vala
    Installer/Backend.vala
    Utils.vala
    ${CMAKE_CURRENT_BINARY_DIR}/config.vala
PACKAGES
    gtk+-3.0
    switchboard-2.0
    granite
	gnome-desktop-3.0
    accountsservice
    posix
    #polkit-gobject-1
OPTIONS
	--vapidir=${CMAKE_CURRENT_SOURCE_DIR}/../vapi/
    --thread
)

add_library (${PLUGNAME} MODULE ${VALA_C})
target_link_libraries(${PLUGNAME} ${DEPS_LIBRARIES})

# Installation
install (TARGETS ${PLUGNAME} DESTINATION ${PKGDATADIR})