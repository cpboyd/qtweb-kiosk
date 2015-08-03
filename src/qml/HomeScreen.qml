/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the QtBrowser project.
**
** $QT_BEGIN_LICENSE:GPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see http://www.qt.io/terms-conditions. For further
** information use the contact form at http://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPLv2 included in the
** packaging of this file. Please review the following information to
** ensure the GNU General Public License version 2 requirements
** will be met: http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3.0 as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL included in the
** packaging of this file. Please review the following information to
** ensure the GNU General Public License version 3.0 requirements will be
** met: http://www.gnu.org/copyleft/gpl.html.
**
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.5
import "assets"

Rectangle {
    id: homeScreen

    property int padding: 60
    property int cellSize: width / 5 - padding
    property alias count: gridView.count
    property alias currentIndex: gridView.currentIndex

    function set(index) {
        currentIndex = index
        gridView.snapToPage()
    }

    state: "disabled"

    signal add(string title, string url, string iconUrl, string fallbackColor)
    onAdd: {
        var element = { "title": title, "url": url, "iconUrl": iconUrl, "fallbackColor": fallbackColor }
        listModel.append(element)
    }

    signal remove(string url, int idx)
    onRemove: {
        var index = idx < 0 ? contains(url) : idx
        if (index < 0)
            return

        listModel.remove(index)
        gridView.forceLayout()
        navigation.refresh()
    }

    function get(index) {
        return listModel.get(index)
    }

    function contains(url) {
        for (var idx = 0; idx < listModel.count; ++idx) {
            if (listModel.get(idx).url === url)
                return idx;
        }
        return -1;
    }

    states: [
        State {
            name: "enabled"
            AnchorChanges {
                target: homeScreen
                anchors.top: navigation.bottom
            }
        },
        State {
            name: "disabled"
            AnchorChanges {
                target: homeScreen
                anchors.top: homeScreen.parent.bottom
            }
        },
        State {
            name: "edit"
        }
    ]

    transitions: Transition {
        AnchorAnimation { duration: animationDuration; easing.type : Easing.InSine }
    }

    ListModel {
        id: listModel
        Component.onCompleted: {
            listModel.clear()
            var string = engine.restoreBookmarks()
            if (!string)
                return
            var list = JSON.parse(string)
            for (var i = 0; i < list.length; ++i) {
                listModel.append(list[i])
            }
            navigation.refresh()
        }
        Component.onDestruction: {
            var list = []
            for (var i = 0; i < listModel.count; ++i) {
                list[i] = listModel.get(i)
            }
            if (!list.length)
                return
            engine.saveBookmarks(JSON.stringify(list))
        }
    }

    GridView {
        id: gridView

        property real dragStart: 0
        property real page: 4 * cellWidth

        anchors.fill: parent
        model: listModel
        cellWidth: homeScreen.cellSize + homeScreen.padding
        cellHeight: cellWidth
        flow: GridView.FlowTopToBottom
        boundsBehavior: Flickable.StopAtBounds
        maximumFlickVelocity: 0
        contentHeight: parent.height

        MouseArea {
            z: -1
            enabled: homeScreen.state == "edit"
            anchors.fill: parent
            onClicked: homeScreen.state = "enabled"
        }

        rightMargin: {
            var margin = (parent.width - 4 * gridView.cellWidth - homeScreen.padding) / 2
            var padding = gridView.page - Math.round(gridView.count % 8 / 2) * gridView.cellWidth

            if (padding == gridView.page)
                return margin

            return margin + padding
        }

        anchors {
            topMargin: toolBarSize
            leftMargin: (parent.width - 4 * gridView.cellWidth + homeScreen.padding) / 2
        }

        Behavior on contentX {
            NumberAnimation { duration: 1.5 * animationDuration; easing.type : Easing.InSine}
        }

        function snapToPage() {
            if (dragging) {
                dragStart = contentX
                return
            }
            if (dragStart == 2 * page && contentX < 2 * page) {
                contentX = page
                return
            }
            if (dragStart == page) {
                if (contentX < page) {
                    contentX = 0
                    return
                }
                if (page < contentX) {
                    contentX = 2 * page
                    return
                }
            }
            if (dragStart == 0 && 0 < contentX) {
                contentX = page
                return
            }
            contentX = 0
        }

        onDraggingChanged: snapToPage()
        delegate: Rectangle {
            id: square
            property string iconColor: "#f6f6f6"
            width: homeScreen.cellSize
            height: width
            border.color: iconStrokeColor
            border.width: 1

            Rectangle {
                id: bg
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    margins: 1
                }
                state: "fallback"
                width: square.width - 2
                height: width
                states: [
                    State {
                        name: "fallback"
                        PropertyChanges {
                            target: square
                            color: fallbackColor
                        }
                        PropertyChanges {
                            target: bg
                            color: square.color
                        }
                    },
                    State {
                        name: "normal"
                        PropertyChanges {
                            target: square
                            color: iconColor
                        }
                        PropertyChanges {
                            target: bg
                            color: square.color
                        }
                    }
                ]

                Image {
                    id: icon
                    smooth: true
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                        topMargin: width < bg.width ? 15 : 0
                    }
                    width: {
                        if (!icon.sourceSize.width)
                            return 0
                        if (icon.sourceSize.width < 100)
                            return 32

                        return bg.width
                    }
                    height: width
                    source: iconUrl
                    onStatusChanged: {
                        switch (status) {
                        case Image.Null:
                        case Image.Loading:
                        case Image.Error:
                            bg.state = "fallback"
                            break
                        case Image.Ready:
                            bg.state = "normal"
                            break
                        }
                    }
                }
                Text {
                    function cleanup(string) {
                        var t = string.replace("-", " ")
                        .replace("|", " ").replace(",", " ")
                        .replace(/\s\s+/g, "\n")
                        return t
                    }

                    visible: icon.width != bg.width
                    text: cleanup(title)
                    font.family: defaultFontFamily
                    font.pixelSize: 18
                    color: bg.state == "fallback" ? "white" : "black"
                    anchors {
                        top: icon.bottom
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        leftMargin: 15
                        rightMargin: 15
                        bottomMargin: 15
                    }
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Rectangle {
                id: overlay
                visible: opacity != 0.0
                anchors.fill: parent
                color: iconOverlayColor
                opacity: {
                    if (iconMouse.pressed) {
                        if (homeScreen.state != "edit")
                            return 0.1
                        return 0.4
                    }
                    if (homeScreen.state == "edit")
                        return 0.3
                    return 0.0
                }
            }
            MouseArea {
                id: iconMouse
                anchors.fill: parent
                onPressAndHold: {
                    if (homeScreen.state == "edit") {
                        homeScreen.state = "enabled"
                        return
                    }
                    homeScreen.state = "edit"
                }
                onClicked: {
                    if (homeScreen.state == "edit") {
                        homeScreen.state = "enabled"
                        return
                    }
                    navigation.load(url)
                }
            }
            Rectangle {
                enabled: homeScreen.state == "edit"
                opacity: enabled ? 1.0 : 0.0
                width: image.sourceSize.width
                height: image.sourceSize.height - 2
                radius: width / 2
                color: iconOverlayColor
                anchors {
                    horizontalCenter: parent.right
                    verticalCenter: parent.top
                }
                Image {
                    id: image
                    opacity: {
                        if (deleteButton.pressed)
                            return 0.70
                        return 1.0
                    }
                    anchors {
                        top: parent.top
                        left: parent.left
                    }
                    source: "qrc:///delete"
                    MouseArea {
                        id: deleteButton
                        anchors.fill: parent
                        onClicked: {
                            mouse.accepted = true
                            remove(url, index)
                        }
                    }
                }
                Behavior on opacity {
                    NumberAnimation { duration: animationDuration }
                }
            }
        }
    }
    Rectangle {
        width: homeScreen.cellSize - homeScreen.padding / 2 - 10
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        MouseArea {
            enabled: homeScreen.state == "edit"
            anchors.fill: parent
            onClicked: homeScreen.state = "enabled"
        }
    }
    Rectangle {
        width: homeScreen.cellSize - homeScreen.padding / 2 - 10
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        MouseArea {
            enabled: homeScreen.state == "edit"
            anchors.fill: parent
            onClicked: homeScreen.state = "enabled"
        }
    }
    Row {
        id: pageIndicator
        spacing: 20
        anchors {
            bottomMargin: 40
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        Rectangle {
            property bool active: gridView.contentX < gridView.page
            width: 10
            height: width
            radius: width / 2
            color: !active ? inactivePagerColor : uiColor
            anchors.verticalCenter: parent.verticalCenter
            MouseArea {
                anchors.fill: parent
                onClicked: gridView.contentX = 0
            }
        }
        Rectangle {
            property bool active: gridView.page <= gridView.contentX && gridView.contentX < 2 * gridView.page
            width: 10
            visible: gridView.count > 8
            height: width
            radius: width / 2
            color: !active ? inactivePagerColor : uiColor
            anchors.verticalCenter: parent.verticalCenter
            MouseArea {
                anchors.fill: parent
                onClicked: gridView.contentX = gridView.page
            }
        }
        Rectangle {
            property bool active: 2 * gridView.page <= gridView.contentX
            width: 10
            visible: gridView.count > 16
            height: width
            radius: width / 2
            color: !active ? inactivePagerColor : uiColor
            anchors.verticalCenter: parent.verticalCenter
            MouseArea {
                anchors.fill: parent
                onClicked: gridView.contentX = 2 * gridView.page
            }
        }
    }

    Rectangle {
        visible: gridView.count == 0
        color: "transparent"
        anchors.centerIn: parent
        width: 500
        height: 300
        Text {
            anchors.centerIn: parent
            color: placeholderColor
            font.family: defaultFontFamily
            font.pixelSize: 28
            text: "No bookmarks have been saved so far."
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
