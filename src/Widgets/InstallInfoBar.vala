public class InstallInfoBar : Gtk.InfoBar {
    protected Gtk.Box box;
    protected Gtk.Label label;
    protected Gtk.ProgressBar progress;
    protected Gtk.Button cancel_button;

    private bool _install_cancellable;
    public void set_cancellable (bool cancellable) {
        _install_cancellable = cancellable;
        cancel_button.set_sensitive (_install_cancellable);
    }

    public signal void cancel_clicked ();

    public InstallInfoBar () {
        this.message_type = Gtk.MessageType.INFO;

        box = get_content_area () as Gtk.Box;

        label = new Gtk.Label (null);

        progress = new Gtk.ProgressBar ();

        cancel_button = new Gtk.Button.with_label (_("Cancel"));
        cancel_button.clicked.connect (() => {
            hide ();
            cancel_clicked ();
        });

        box.pack_start (label, false);
        box.pack_end (cancel_button, false);
        box.pack_end (progress, false);

        show_all ();
    }

    public void set_transaction_mode (UbuntuInstaller.TransactionMode transaction_mode) {
        switch (transaction_mode) {
            case UbuntuInstaller.TransactionMode.INSTALL:
                label.set_label (_("installing language"));
                break;
            case UbuntuInstaller.TransactionMode.REMOVE:
                label.set_label (_("removing language"));
                break;
            case UbuntuInstaller.TransactionMode.INSTALL_MISSING:
                label.set_label (_("installing missing language"));
                break;
        }
    }

    public void set_progress (int progress) {
        if (progress >= 100)
            hide ();
        else
            show ();
        this.progress.set_fraction(progress/100.0);
    }
}
