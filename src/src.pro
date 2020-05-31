TARGET = qtwebbrowser

CONFIG += c++11
CONFIG -= app_bundle

SOURCES = \
    appengine.cpp \
    main.cpp \
    touchtracker.cpp

HEADERS = \
    appengine.h \
    touchtracker.h \

OTHER_FILES = \
    qml/assets/UIButton.qml \
    qml/ApplicationRoot.qml \
    qml/BrowserWindow.qml \
    qml/FeaturePermissionBar.qml \
    qml/MockTouchPoint.qml \
    qml/PageView.qml \
    qml/Keyboard.qml \
    qml/Window.qml

QT += qml quick webengine

RESOURCES += resources.qrc

!cross_compile {
    DEFINES += DESKTOP_BUILD
    SOURCES += touchmockingapplication.cpp
    HEADERS += touchmockingapplication.h
    QT += gui-private
    isEmpty(INSTALL_PREFIX): INSTALL_PREFIX=/usr/local/bin
} else {
    # Path for Qt for Device Creation
    isEmpty(INSTALL_PREFIX): INSTALL_PREFIX=/data/user/qt/qtwebbrowser-app
}

target.path = $$INSTALL_PREFIX
INSTALLS += target
