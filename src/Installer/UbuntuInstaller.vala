public class UbuntuInstaller : Object {

		static const string LANGUAGE_CHECKER = "/usr/bin/check-language-support";
	static const string LOCALES_INSTALLER = "/usr/share/locales/install-language-pack";
	static const string LOCALES_REMOVER = "/usr/share/locales/install-language-pack";

	//check-language-support -l fr

	AptdProxy aptd;

public signal void install_finished ();
	public signal void remove_finished ();

	public UbuntuInstaller () {
		aptd = new AptdProxy ();
		aptd.connect_to_aptd ();
	}

	public bool install (string packages_string) {
		message("Packages to install: %s", packages_string);
		var packages = packages_string.split (" ");
		packages[packages.length - 1] = null;

	/*	var copy = new string[packages.length+1];
		int i = 0;
		foreach (var packet in packages) {
			copy[i++] = packet;
		}

		copy[packages.length] = null;

	*/
		foreach (var packet in packages) {
			message("Packet: %s", packet);
		}

		aptd.install_packages.begin (packages, (obj, res) => {
			var test = aptd.install_packages.end (res);
			var proxy = new AptdTransactionProxy ();
			proxy.finished.connect (on_apt_finshed);
			proxy.connect_to_aptd (test);
			proxy.simulate ();
			proxy.run ();

			warning (test);

		});
		return true;
	}

	public bool remove (string language) {

		var inst = get_installed_packages (language);
		message (inst);
		var installed = inst.strip().split(" ");
		var miss = get_remaining_packages (language);
		message (miss);
		var missing = miss.strip().split(" ");


		var total_remove = new Gee.ArrayList<string>(null);//[installed.length];
		var i = 0;
		foreach (var inst_lang in installed) {
			bool not_installed = false;
			foreach (var miss_lang in missing) {
				if (miss_lang == inst_lang) {
					not_installed = true;
				}
			}

			if (!not_installed) {
				total_remove.add (inst_lang);
				message("Packages remove: %s", inst_lang);
			} else {
				message("Packages not remove: %s", inst_lang);
			}
		}


		var remove_list = new string[total_remove.size];
		i = 0;
		total_remove.@foreach ((val) => {
			remove_list[i++] = val;
			return true;
		});

		

		aptd.remove_packages.begin (remove_list, (obj, res) => {
			var test = aptd.remove_packages.end (res);
			var proxy = new AptdTransactionProxy ();
			proxy.finished.connect (on_apt_finshed);
			proxy.connect_to_aptd (test);
			proxy.simulate ();
			proxy.run ();

			warning (test);

		});
		return true;
	}

	void on_apt_finshed (string id) {
		message ("Transaction ID finished: %s", id);
		install_finished ();
	}


	string get_remaining_packages (string langcode) {

		string output;
		int status;

		Pid pid;
		Process.spawn_sync (null, 
			{LANGUAGE_CHECKER, "-l", langcode.substring (0, 2) , null}, 
			Environ.get (),
			SpawnFlags.SEARCH_PATH,
			null,
			out output,
			null,
			out status);

		return output;
	}

	string get_installed_packages (string langcode) {

		string output;
		int status;

		Pid pid;
		Process.spawn_sync (null, 
			{LANGUAGE_CHECKER, "--show-installed", "-l", langcode.substring (0, 2) , null}, 
			Environ.get (),
			SpawnFlags.SEARCH_PATH,
			null,
			out output,
			null,
			out status);

		return output;
	}
}