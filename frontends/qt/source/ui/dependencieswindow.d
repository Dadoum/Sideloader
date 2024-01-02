module ui.dependencieswindow;

import core.stdcpp.new_: cpp_new;
import core.thread;

import file = std.file;
import std.path;

import slf4d;

import provision;

import qt.core.namespace;
import qt.core.object;
import qt.core.thread;
import qt.gui.event;
import qt.helpers;
import qt.widgets.dialog;
import qt.widgets.progressbar;
import qt.widgets.ui;
import qt.widgets.boxlayout;

import app;

alias DependenciesWindowUI = UIStruct!"dependencieswindow.ui";

class DependenciesWindow: QDialog {
    mixin(Q_OBJECT_D);

    string configurationPath;
    void delegate(Device, ADI) successCallback;

    DependenciesWindowUI* ui;

    this(string configurationPath, void delegate(Device, ADI) successCallback) {
        this.configurationPath = configurationPath;
        this.successCallback = successCallback;

        ui = cpp_new!DependenciesWindowUI();
        ui.setupUi(this);

        QObject.connect(this.signal!"finished", this.slot!"applyAction");
        QObject.connect(this.signal!"downloadFinished", this.slot!"executeCallback");
    }

    @QSignal final void downloadFinished() { mixin(Q_SIGNAL_IMPL_D); }

    @QSlot
    final void executeCallback() {
        auto log = getLogger();
        log.info("Download done.");

        scope provisioningData = initializeADI(configurationPath);
        successCallback(provisioningData.device, provisioningData.adi);
    }

    @QSlot
    final void applyAction(int result) {
        assert(QThread.currentThread() == this.thread());

        if (result == 1) {
            auto window = new class QDialog {
                mixin(Q_OBJECT_D);

                bool canClose = false;
                QProgressBar progressBar;

                this() {
                    super();

                    QVBoxLayout verticalLayout = cpp_new!QVBoxLayout(this);
                    progressBar = cpp_new!QProgressBar();
                    progressBar.setRange(0, 100);
                    verticalLayout.addWidget(progressBar);
                    this.setWindowModality(WindowModality.ApplicationModal);

                    QObject.connect(this.signal!"progressMade", this.slot!"updateProgressBar");
                }

                extern(C++) override void closeEvent(QCloseEvent event) {
                    if (!canClose) {
                        event.ignore();
                        return;
                    }
                    super.closeEvent(event);
                }

                @QSignal final void progressMade(int progressPercent) { mixin(Q_SIGNAL_IMPL_D); }

                @QSlot
                final void updateProgressBar(int progressPercent) {
                    if (progressPercent < 100) {
                        progressBar.setValue(progressPercent);
                    } else {
                        progressBar.setRange(0, 0);
                    }
                }
            };
            window.show();
            new Thread({
                auto log = getLogger();
                log.info("Downloading Apple's APK.");
                auto succeeded = downloadAndInstallDeps(configurationPath, (progress) {
                    window.progressMade(cast(int) (progress * 100));
                    return false;
                });

                if (succeeded) {
                    log.info("Download successful.");
                    this.downloadFinished();
                } else {
                    log.info("Download failed :(");
                }
                window.canClose = true;
                window.close();
            }).start();
        }
    }

    static void ensureDeps(string configurationPath, void delegate(Device, ADI) successCallback) {
        if (!(file.exists(configurationPath.buildPath("lib/libstoreservicescore.so")) && file.exists(configurationPath.buildPath("lib/libCoreADI.so")))) {
            auto log = getLogger();
            log.info("Download required.");
            auto dependenciesWindow = new DependenciesWindow(configurationPath, successCallback);
            dependenciesWindow.show();
        } else {
            scope provisioningData = initializeADI(configurationPath);
            successCallback(provisioningData.device, provisioningData.adi);
        }
    }
}


