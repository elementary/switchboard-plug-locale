<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC
 "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd">
<policyconfig>
  <vendor>elementary</vendor>
  <vendor_url>http://elementaryos.org/</vendor_url>

  <action id="org.pantheon.switchboard.locale.administration">
    <description gettext-domain="@GETTEXT_PACKAGE@">Manage locale settings </description>
    <message gettext-domain="@GETTEXT_PACKAGE@">Authentication is required to manage locale settings</message>
    <icon_name>preferences-desktop-locale</icon_name>
    <defaults>
      <allow_any>no</allow_any>
      <allow_inactive>no</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/usr/bin/localectl</annotate>
    <annotate key="org.freedesktop.policykit.imply">org.freedesktop.locale1.set-locale</annotate>
    <annotate key="org.freedesktop.policykit.imply">org.debian.apt.install-or-remove-packages</annotate>
  </action>

</policyconfig>
