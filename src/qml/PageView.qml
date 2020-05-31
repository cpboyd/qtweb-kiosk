/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the Qt WebBrowser application.
**
** $QT_BEGIN_LICENSE:GPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 or (at your option) any later version
** approved by the KDE Free Qt Foundation. The licenses are as published by
** the Free Software Foundation and appearing in the file LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.5
import QtWebEngine 1.9
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.2

import WebBrowser 1.0
import "assets"

Rectangle {
    id: root

    property alias webView: webEngineView
    property bool interactive: true

    property QtObject defaultProfile: WebEngineProfile {
        storageName: "YABProfile"
        offTheRecord: false
        useForGlobalCertificateVerification: true
    }

    anchors.fill: parent

    Action {
        shortcut: "Ctrl+R"
        onTriggered: {
            if (webView)
                webView.reload()
        }
    }

    Action {
        shortcut: "Ctrl+0"
        onTriggered: {
            if (webView)
                webView.zoomFactor = 1.0;
        }
    }
    Action {
        shortcut: "Ctrl+-"
        onTriggered: {
            if (webView)
                webView.zoomFactor -= 0.1;
        }
    }
    Action {
        shortcut: "Ctrl+="
        onTriggered: {
            if (webView)
                webView.zoomFactor += 0.1;
        }
    }

    Action {
        shortcut: "Ctrl+F"
        onTriggered: {
            findBar.visible = !findBar.visible
            if (findBar.visible) {
                findTextField.forceActiveFocus()
            }
        }
    }

    Action {
        shortcut: "Esc"
        onTriggered: {
            if (findBar.visible) {
                findBar.visible = false
                return
            }
        }
    }

    FeaturePermissionBar {
        id: permBar
        view: webEngineView
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        z: 3
    }

    WebEngineView {
        id: webEngineView

        anchors {
            fill: parent
            top: permBar.bottom
        }

        profile: defaultProfile
        enabled: root.interactive
        property bool isInitialLoad: true

        Timer {
            id: timer
            function setTimeout(cb, delayTime) {
                timer.interval = delayTime;
                timer.repeat = false;
                timer.triggered.connect(cb);
                timer.triggered.connect(function release () {
                    timer.triggered.disconnect(cb); // This is important
                    timer.triggered.disconnect(release); // This is important as well
                });
                timer.start();
            }
        }

        // Trigger a refresh to check if the new url is bookmarked.
        onUrlChanged: {}

        onLoadingChanged: {
            if (!isInitialLoad) {
                return;
            }
            print("onLoadingChanged " + loadRequest.status);
            switch (loadRequest.status) {
            case WebEngineLoadRequest.LoadFailedStatus:
                if (loadRequest.errorDomain == WebEngineView.ConnectionErrorDomain) {
                    print(loadRequest.errorString)
                    timer.setTimeout(function() {
                        print("reload initial url")
                        reload();
                    }, 5000);
                }
                break;
            case WebEngineLoadRequest.LoadSucceededStatus:
                isInitialLoad = false;
                break;
            default:
                break;
            }
        }

        onCertificateError: {
            var domain = AppEngine.domainFromString(error.url);
            print("certificate error " + domain + ": " + error.description);
            if (domain !== 'localhost' && !acceptedCertificates.shouldAutoAccept(error)){
                error.defer()
                sslDialog.enqueue(error)
            } else{
                error.ignoreCertificateError()
            }
        }

        onNewViewRequested: {
            var tab = tabComponent
            if (!request.userInitiated) {
                print("Warning: Blocked a popup window.")
                return
            }

            if (!tab)
                return

            request.openIn(tab.webView)
        }

        onFeaturePermissionRequested: {
            permBar.securityOrigin = securityOrigin;
            permBar.requestedFeature = feature;
            permBar.visible = true;
        }

        onFullScreenRequested: {
            request.accept()
        }
    }

    TouchTracker {
        id: tracker
        enabled: root.interactive
        target: webEngineView
        anchors.fill: parent
        onTouchYChanged: browserWindow.touchY = tracker.touchY
        onYVelocityChanged: browserWindow.velocityY = yVelocity
        onTouchBegin: {
            browserWindow.touchY = tracker.touchY
            browserWindow.velocityY = yVelocity
            browserWindow.touchReference = tracker.touchY
            browserWindow.touchGesture = true
        }
        onTouchEnd: {
            browserWindow.velocityY = yVelocity
            browserWindow.touchGesture = false
        }
        onScrollDirectionChanged: {
            browserWindow.velocityY = 0
            browserWindow.touchReference = tracker.touchY
        }
    }

    Rectangle {
        opacity: webEngineView.isInitialLoad ? 1.0 : 0.0
        anchors.fill: parent
        visible: opacity != 0.0
        color: "white"

        BusyIndicator {
            anchors.centerIn: parent
            running: webEngineView.isInitialLoad
        }

        Behavior on opacity {
            NumberAnimation { duration: animationDuration }
        }
    }

    Rectangle {
        id: findBar
        anchors {
            right: webEngineView.right
            left: webEngineView.left
            top: webEngineView.top
        }
        height: toolBarSize / 2 + 10
        visible: false
        color: uiColor

        RowLayout {
            spacing: 0
            anchors.fill: parent
            Rectangle {
                width: 5
                height: parent.height
                color: uiColor
            }
            TextField {
                id: findTextField
                Layout.fillWidth: true
                onAccepted: {
                    webEngineView.findText(text)
                }
                style: TextFieldStyle {
                    textColor: "black"
                    font.family: defaultFontFamily
                    font.pixelSize: 28
                    selectionColor: uiHighlightColor
                    selectedTextColor: "black"
                    placeholderTextColor: placeholderColor
                    background: Rectangle {
                        implicitWidth: 514
                        implicitHeight: toolBarSize / 2
                        border.color: textFieldStrokeColor
                        border.width: 1
                    }
                }
            }
            Rectangle {
                width: 5
                height: parent.height
                color: uiColor
            }
            Rectangle {
                width: 1
                height: parent.height
                color: uiSeparatorColor
            }
            UIButton {
                id: findBackwardButton
                iconSource: "assets/icons/Btn_Back.png"
                implicitHeight: parent.height
                onClicked: webEngineView.findText(findTextField.text, WebEngineView.FindBackward)
            }
            Rectangle {
                width: 1
                height: parent.height
                color: uiSeparatorColor
            }
            UIButton {
                id: findForwardButton
                iconSource: "assets/icons/Btn_Forward.png"
                implicitHeight: parent.height
                onClicked: webEngineView.findText(findTextField.text)
            }
            Rectangle {
                width: 1
                height: parent.height
                color: uiSeparatorColor
            }
            UIButton {
                id: findCancelButton
                iconSource: "assets/icons/Btn_Clear.png"
                implicitHeight: parent.height
                onClicked: findBar.visible = false
            }
        }
    }
}
