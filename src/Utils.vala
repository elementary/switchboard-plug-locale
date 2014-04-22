public class Utils : Object{

	Gee.HashMap<string,string> lang_map;
	Gee.HashMap<string,string> country_map;

	public Utils () {

		lang_map = new Gee.HashMap<string,string> (null, null);
		country_map = new Gee.HashMap<string,string> (null, null);

/*
		Xml.Doc* doc = Xml.Parser.parse_file ("/usr/share/xml/iso-codes/iso_639_3.xml");
		var node = doc->get_root_element ();

		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
            // Spaces between tags are also nodes, discard them
            if (iter->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            var lang = "";
            var code = "";
            var cn = iter->has_prop ("common_name");
            if (cn != null){
            	lang = iter->get_prop ("common_name");
            } else {
            	lang = iter->get_prop ("name");
            }

            var p1 = iter->has_prop ("part1_code");
            if (cn != null){
            	code = iter->get_prop ("part1_code");
            } else {
            	code = iter->get_prop("id");
            }
            //message("%s:%s",code, lang);

            lang_map.@set (code, lang);
        }

        doc = Xml.Parser.parse_file ("/usr/share/xml/iso-codes/iso_3166.xml");
		node = doc->get_root_element ();

		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
            // Spaces between tags are also nodes, discard them
            if (iter->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            var descr = "";
            var code = "";
            var cn = iter->has_prop ("common_name");
            if (cn != null){
            	descr = iter->get_prop ("common_name");
            } else {
            	descr = iter->get_prop ("name");
            }

            var p1 = iter->has_prop ("alpha_2_code");
            if (cn != null){
            	code = iter->get_prop ("alpha_2_code");
            } else {
            	code = iter->get_prop("alpha_3_code");
            }

            //message("%s:%s",code, descr);
            country_map.set (code, descr);
        }
*/

	}
	
	public static string[] get_installed_languages () {

		string output;
		int status;

		Pid pid;
		Process.spawn_sync (null, 
			{"/usr/share/language-tools/language-options" , null}, 
			Environ.get (),
			SpawnFlags.SEARCH_PATH,
			null,
			out output,
			null,
			out status);
		message( "output: %s", output);
		return output.split("\n");
	}

	public static string[] get_installed_locales () {

		string output;
		int status;

		Pid pid;
		Process.spawn_sync (null, 
			{"/usr/share/language-tools/language-options" , null}, 
			Environ.get (),
			SpawnFlags.SEARCH_PATH,
			null,
			out output,
			null,
			out status);
		message( "output: %s", output);
		return output.split("\n");
	}

	public string translate_language (string lang) {
		message ("looking up: lang %s", lang);
		if (lang_map.has_key (lang)) {
			var lang_name = dgettext("iso_639", lang_map.get(lang));
			if (lang_name == lang_map.get(lang)) {
				lang_name = dgettext("iso_639_3", lang_map.get(lang));
			}
			return lang_name;
		} else {
			return lang;
		}
	}

	public string translate_country (string countrycode) {

		if (country_map.has_key (countrycode)) {
			return dgettext("iso_3166", country_map.get(countrycode));
		} else {
			return countrycode;
		}
	}

	static Utils? instance = null;

	public static Utils get_default () {
		if (instance == null) {
			instance = new Utils ();
		}
		return instance;
	}
}