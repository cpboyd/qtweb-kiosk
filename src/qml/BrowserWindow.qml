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
import QtWebEngine 1.1

import QtQuick.Controls 1.0
import QtQuick.Controls.Styles 1.0
import QtQuick.Layouts 1.0
import QtQuick.Controls.Private 1.0
import QtQuick.Dialogs 1.2

import "assets"
import WebBrowser 1.0

Item {
    id: browserWindow

    property int toolBarSize: 80
    property string uiColor: "#46a2da"
    property string uiSeparatorColor: "#7ebee5"
    property string buttonPressedColor: "#3f91c4"
    property string emptyBackgroundColor: "#e4e4e4"
    property string uiHighlightColor: "#fddd5c"
    property string textFieldStrokeColor: "#3882ae"
    property string placeholderColor: "#a0a1a2"
    property string defaultFontFamily: "Open Sans"

    property int animationDuration: 200
    property int velocityThreshold: 400
    property int velocityY: 0
    property real touchY: 0
    property real touchReference: 0
    property bool touchGesture: false

    property alias webView: tabView.webView

    width: 1024
    height: 600
    visible: true

    ProgressBar {
        id: progressBar

        visible: (webView && !webView.isInitialLoad && webView.loadProgress < 100)
        opacity: visible ? 1.0 : 0.0
        height:  visible ? 3 : 0

        anchors {
            left: parent.left
            right: parent.right
        }

        style: ProgressBarStyle {
            background: Rectangle {
                height: 3
                color: emptyBackgroundColor
            }
            progress: Rectangle {
                color: "#317198"
            }
        }

        minimumValue: 0
        maximumValue: 100
        value: visible ? webView.loadProgress : 0
        z: 5
    }

    PageView {
        id: tabView
        interactive: !sslDialog.visible

        anchors {
            top: progressBar.bottom
            left: parent.left
            right: parent.right
        }

        height: inputPanel.y

        Component.onCompleted: {
            webView.url = AppEngine.initialUrl
        }
    }

    QtObject{
        id: acceptedCertificates

        property var acceptedUrls : []

        function shouldAutoAccept(certificateError){
            var domain = AppEngine.domainFromString(certificateError.url)
            return acceptedUrls.indexOf(domain) >= 0
        }
    }

    MessageDialog {
        id: sslDialog

        property var certErrors: []
        property var currentError: null
        visible: certErrors.length > 0
        icon: StandardIcon.Warning
        standardButtons: StandardButton.No | StandardButton.Yes
        title: "Server's certificate not trusted"
        text: "Do you wish to continue?"
        detailedText: "If you wish so, you may continue with an unverified certificate. " +
                      "Accepting an unverified certificate means " +
                      "you may not be connected with the host you tried to connect to.\n" +
                      "Do you wish to override the security check and continue?"
        onYes: {
            var cert = certErrors.shift()
            var domain = AppEngine.domainFromString(cert.url)
            acceptedCertificates.acceptedUrls.push(domain)
            cert.ignoreCertificateError()
            presentError()
        }
        onNo: reject()
        onRejected: reject()

        function reject(){
            certErrors.shift().rejectCertificate()
            presentError()
        }
        function enqueue(error){
            currentError = error
            certErrors.push(error)
            presentError()
        }
        function presentError(){
            informativeText = "SSL error from URL\n\n" + currentError.url + "\n\n" + currentError.description + "\n"
        }
    }
}
