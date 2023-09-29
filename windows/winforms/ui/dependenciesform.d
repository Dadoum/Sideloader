module ui.dependenciesform;

import core.thread;

import std.format;

import slf4d;

import dfl;

import constants;
import main;

class DependenciesForm: Form {
    private ProgressBar downloadProgressBar;
    private Button proceedButton;
    private Label label1;
    private __gshared bool succeeded = false;
    private __gshared bool abort = false;
    private Thread dlThread;

    this() {
        this.downloadProgressBar = new ProgressBar();
        this.proceedButton = new Button();
        this.label1 = new Label();
        this.suspendLayout();
        //
        // downloadProgressBar
        //
        this.downloadProgressBar.location = Point(13, 120);
        this.downloadProgressBar.maximum = 1000;
        this.downloadProgressBar.name = "downloadProgressBar";
        this.downloadProgressBar.size = Size(218, 29);
        // this.downloadProgressBar.tabIndex = 0;
        //
        // proceedButton
        //
        this.proceedButton.click ~= &proceedButton_Clicked;
        this.proceedButton.location = Point(237, 120);
        this.proceedButton.name = "proceedButton";
        this.proceedButton.size = Size(85, 29);
        // this.proceedButton.tabIndex = 1;
        this.proceedButton.text = "Proceed";
        // this.proceedButton.useVisualStyleBackColor = true;
        //
        // label1
        //
        this.label1.location = Point(10, 9);
        this.label1.name = "label1";
        this.label1.size = Size(312, 108);
        // this.label1.tabIndex = 2;
        this.label1.text = applicationName ~ " requires some libraries to be installed.\nInstalling them will cause a ≈150 MB download and 5 MB of storage space.\n\nProceed?";
        //
        // DependenciesForm
        //
        // this.autoScaleDimensions = SizeF(6F, 13F);
        // this.autoScaleMode = AutoScaleMode.Font;
        this.clientSize = Size(334, 161);
        this.controls.add(this.label1);
        this.controls.add(this.proceedButton);
        this.controls.add(this.downloadProgressBar);
        this.formBorderStyle = FormBorderStyle.FIXED_DIALOG;
        this.name = "DependenciesForm";
        this.startPosition = FormStartPosition.CENTER_PARENT;
        this.text = "Downloads required";
        this.resumeLayout(false);

        dlThread = new Thread(() {
            succeeded = frontend.downloadAndInstallDeps((progress) {
                auto progressPercentage = progress * 100;
                this.invoke({
                    downloadProgressBar.value = cast(int) (progressPercentage * 10);
                    downloadProgressBar.text = format!"%.2f %% completed"(progressPercentage);
                });

                return abort;
            });

            this.invoke(() => this.close());
        });
    }

    override void onClosed(EventArgs ea) {
        super.onClosed(ea);

        if (succeeded) {
            frontend.initializeADI();
            this.close();
        } else {
            if (dlThread.isRunning() && !abort) {
                abort = true;
            } else {
                Application.exit();
            }
        }
    }

    void proceedButton_Clicked(Control c, EventArgs e) {
        cursor = Cursors.waitCursor();
        proceedButton.enabled = false;
        dlThread.start();
    }
}
