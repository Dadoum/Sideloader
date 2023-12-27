module ui.mainwindow;

import core.stdcpp.new_: cpp_new;

import qt.config;
import qt.core.coreevent;
import qt.core.string;
import qt.core.translator;
import qt.helpers;
import qt.widgets.action;
import qt.widgets.mainwindow;
import qt.widgets.ui;
import qt.widgets.widget;

alias MainWindowUI = UIStruct!"mainwindow.ui";

class MainWindow: QMainWindow {
    MainWindowUI* ui;

    mixin(Q_OBJECT_D);
    this() {
        setWindowTitle(QString("Sideloader"));

        ui = cpp_new!MainWindowUI();
        ui.setupUi(this);
    }
}
