public class LanguageInstaller : Object {


	UbuntuInstaller ui;

	Permission permission;

	public signal void install_finished ();
	public signal void remove_finished ();

	
	public LanguageInstaller () {
		ui = new UbuntuInstaller ();

		ui.install_finished.connect (() => {
			install_finished ();
		});

		ui.remove_finished.connect (() => {
			remove_finished ();
		});


		
	}

	string to_install = "";

	public void install (string language) {
		message("installing language: %s", language);

		//var install = ui.get_remaining_packages (language);

		//ui.install (install);

		
	}

	public void remove (string language) {
		message("remove language: %s", language);

		//var removing = ui.get_installed_packages (language);

		ui.remove (language);

		
	}

	void on_permission_changed (ParamSpec? spec) {
		bool can_acquire = permission.get_can_acquire ();
		bool allowed = permission.get_allowed ();

		if (allowed) {
			
			//ui.install (to_install);
		}
	}


	void _install (string language) {

		/*IOChannel outp = new IOChannel.unix_new (output);
        outp.add_watch (IOCondition.IN | IOCondition.HUP, (channel, condition) => {
        	if (condition == IOCondition.HUP) {
		        return false;
		    }

            try {

	            string line;
	            channel.read_line (out line, null, null);
	            message(line);
	        } catch (Error e) {
	            	message(e.message);
	        }

	        return true;

            //return process_line (channel, condition, "stdout");
        });*/

	}

	static LanguageInstaller? instance = null;

	public static LanguageInstaller get_default () {
		if (instance == null) {
			instance = new LanguageInstaller ();
		}
		return instance;
	}
}