/***
  Copyright (C) 2011-2012 Switchboard Locale Plug Developers
  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.
  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.
  You should have received a copy of the GNU General Public License along
  with this program. If not, see 
***/

public class Utils : Object{

    public Utils () {

    }
    
    public static string[]? get_installed_languages () {

        string output;
        int status;

        try {
            Process.spawn_sync (null, 
                {"/usr/share/language-tools/language-options" , null}, 
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                out output,
                null,
                out status);

            return output.split("\n");

        } catch (Error e) {
            return null;
        }

        
    }

    public static async string[]? get_missing_languages () {

        /* string output; */
        string final = null;
        Pid pid;
        int status;
        int input;
        int output;
        int error;

        try {
            Process.spawn_async_with_pipes (null,
                {"check-language-support", null},
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                out pid,
                out input,
                out output,
                out error);
            UnixInputStream read_stream = new UnixInputStream (output, true);
            DataInputStream out_channel = new DataInputStream (read_stream);
            string line = null;
            final = "";
            while ((line = yield out_channel.read_line_async (Priority.DEFAULT)) != null) {
                final += line;
            }

            if (final != null)
                return final.strip ().split (" ");
            else
                return null;
        } catch (Error e) {
            return null;
        }
    }
    public static Gee.ArrayList<string>? get_installed_locales () {

        string output;
        int status;

        Gee.ArrayList<string>locales = new Gee.ArrayList<string> ();

        try {
            Process.spawn_sync (null, 
                {"locale", "-a" , null}, 
                Environ.get (),
                SpawnFlags.SEARCH_PATH,
                null,
                out output,
                null,
                out status);

            foreach (var line in output.split("\n")) {
                if (".utf8" in line)
                    locales.add (line[0:5]);   
            }

            return locales;
        
        } catch (Error e) {
            return null;
        }

    }


    public static string translate_language (string lang) {
        Intl.textdomain ("iso_639");
        var lang_name = dgettext ("iso_639", lang);
        lang_name = dgettext ("iso_639_3", lang);

        return lang_name;
    }

    public static string translate_country (string country) {
        return dgettext ("iso_3166", country);
    }

    public static string translate (string locale) {
        var current_language = Environment.get_variable ("LANGUAGE");
        Environment.set_variable ("LANGUAGE", locale, true);

        var lang_name = translate_language (Gnome.Languages.get_language_from_locale (locale, null));

        Environment.set_variable ("LANGUAGE", current_language, true);

        return lang_name;
    }

    static Utils? instance = null;

    public static Utils get_default () {
        if (instance == null) {
            instance = new Utils ();
        }
        return instance;
    }
}
