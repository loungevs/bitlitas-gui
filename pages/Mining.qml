// Copyright (c) 2018, Bitlitas
// All rights reserved. Based on Monero.

import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2
import "../components"
import bitlitasComponents.Wallet 1.0

Rectangle {
    id: root
    color: "#F0EEEE"
    property var currentHashRate: 0
    property var forkPid: 0


    function isDaemonLocal() {
        if (appWindow.currentDaemonAddress === "")
            return false
        var daemonHost = appWindow.currentDaemonAddress.split(":")[0]
        if (daemonHost === "127.0.0.1" || daemonHost === "localhost")
            return true
        return false
    }

    /* main layout */
    ColumnLayout {
        id: mainLayout
        anchors.margins: 40
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 20

        // pool
        ColumnLayout {
            id: poolBox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 20

            Label {
                id: poolTitleLabel
                fontSize: 24
                text: qsTr("Pool mining") + translationManager.emptyString
            }


            Text {
                id: poolMainLabel
                text: qsTr("We recommend you to use pool mining. Going solo means you won’t have to share the reward, but your odds of getting a reward are significantly decreased. Although a pool has a much larger chance of solving a block and winning the reward, that reward will be split between all the pool members.") + translationManager.emptyString
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            RowLayout {
                id: poolMinerThreadsRow
                Label {
                    id: poolMinerThreadsLabel
                    color: "#4A4949"
                    text: qsTr("CPU threads") + translationManager.emptyString
                    fontSize: 16
                    Layout.preferredWidth: 120
                }
                LineEdit {
                    id: poolMinerThreadsLine
                    Layout.preferredWidth:  200
                    text: "1"
                    placeholderText: qsTr("(optional)") + translationManager.emptyString
                    validator: IntValidator { bottom: 1 }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Label {
                    id: poolSelect
                    text: qsTr("Pool") + translationManager.emptyString
                }

                ListModel {
                    id: poolModel
                    ListElement { column1: "pool.bitlitas.lt:3333" ; column2: ""; pool: 1}

                }

                StandardDropdown {
                    Layout.fillWidth: true
                    id: poolDropdown
                    shadowReleasedColor: "#306d30"
                    shadowPressedColor: "#B32D00"
                    releasedColor: "#499149"
                    pressedColor: "#306d30"
                }
            }


            RowLayout {
                StandardButton {
                    visible: true
                    id: startPoolMinerButton
                    width: 110
                    text: qsTr("Start mining") + translationManager.emptyString
                    shadowReleasedColor: "#306d30"
                    shadowPressedColor: "#B32D00"
                    releasedColor: "#499149"
                    pressedColor: "#306d30"
                    onClicked: {
                        var success = walletManager.startPoolMining(appWindow.currentWallet.address, poolMinerThreadsLine.text)
                        if (success) {
                            forkPid = success;
                            update()
                        } else {
                            errorPopup.title  = qsTr("Error starting mining") + translationManager.emptyString;
                            errorPopup.text = qsTr("Couldn't start mining.<br>")
                            errorPopup.icon = StandardIcon.Critical
                            errorPopup.open()
                        }
                    }
                }

                StandardButton {
                    id: stopPoolMinerButton
                    width: 110
                    text: qsTr("Stop mining") + translationManager.emptyString
                    shadowReleasedColor: "#306d30"
                    shadowPressedColor: "#B32D00"
                    releasedColor: "#499149"
                    pressedColor: "#306d30"
                    visible: !isWindows && !isAndroid && !isIOS
                    onClicked: {
                        walletManager.stopPoolMining(forkPid)
                        update()
                    }
                }
            }
        }

        // solo
        ColumnLayout {
            id: soloBox
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: -100
            spacing: 20

            Label {
                id: soloTitleLabel
                fontSize: 24
                text: qsTr("Solo mining") + translationManager.emptyString
            }

            Label {
                id: soloLocalDaemonsLabel
                fontSize: 18
                color: "#D02020"
                text: qsTr("(only available for local daemons)")
                visible: !isDaemonLocal()
            }

            Text {
                id: soloMainLabel
                text: qsTr("Mining with your computer helps strengthen the Bitlitas network. The more that people mine, the harder it is for the network to be attacked, and every little bit helps.<br> <br>Mining also gives you a small chance to earn some Bitlitas. Your computer will create hashes looking for block solutions. If you find a block, you will get the associated reward. Good luck!") + translationManager.emptyString
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            RowLayout {
                id: soloMinerThreadsRow
                Label {
                    id: soloMinerThreadsLabel
                    color: "#4A4949"
                    text: qsTr("CPU threads") + translationManager.emptyString
                    fontSize: 16
                    Layout.preferredWidth: 120
                }
                LineEdit {
                    id: soloMinerThreadsLine
                    Layout.preferredWidth:  200
                    text: "1"
                    placeholderText: qsTr("(optional)") + translationManager.emptyString
                    validator: IntValidator { bottom: 1 }
                }
            }

            RowLayout {
                Layout.leftMargin: 125
                CheckBox {
                    id: backgroundMining
                    enabled: startSoloMinerButton.enabled
                    checked: persistentSettings.allow_background_mining
                    onClicked: {persistentSettings.allow_background_mining = checked}
                    text: qsTr("Background mining (experimental)") + translationManager.emptyString
                    checkedIcon: "../images/checkedVioletIcon.png"
                    uncheckedIcon: "../images/uncheckedIcon.png"
                }

            }

            RowLayout {
                // Disable this option until stable
                visible: false
                Layout.leftMargin: 125
                CheckBox {
                    id: ignoreBattery
                    enabled: startSoloMinerButton.enabled
                    checked: !persistentSettings.miningIgnoreBattery
                    onClicked: {persistentSettings.miningIgnoreBattery = !checked}
                    text: qsTr("Enable mining when running on battery") + translationManager.emptyString
                    checkedIcon: "../images/checkedVioletIcon.png"
                    uncheckedIcon: "../images/uncheckedIcon.png"
                }
            }

            RowLayout {
                StandardButton {
                    visible: true
                    //enabled: !walletManager.isMining()
                    id: startSoloMinerButton
                    width: 110
                    text: qsTr("Start mining") + translationManager.emptyString
                    shadowReleasedColor: "#306d30"
                    shadowPressedColor: "#B32D00"
                    releasedColor: "#499149"
                    pressedColor: "#306d30"
                    onClicked: {
                        var success = walletManager.startMining(appWindow.currentWallet.address, soloMinerThreadsLine.text, persistentSettings.allow_background_mining, persistentSettings.miningIgnoreBattery)
                        if (success) {
                            update()
                        } else {
                            errorPopup.title  = qsTr("Error starting mining") + translationManager.emptyString;
                            errorPopup.text = qsTr("Couldn't start mining.<br>")
                            if (!isDaemonLocal())
                                errorPopup.text += qsTr("Mining is only available on local daemons. Run a local daemon to be able to mine.<br>")
                            errorPopup.icon = StandardIcon.Critical
                            errorPopup.open()
                        }
                    }
                }

                StandardButton {
                    visible: true
                    //enabled:  walletManager.isMining()
                    id: stopSoloMinerButton
                    width: 110
                    text: qsTr("Stop mining") + translationManager.emptyString
                    shadowReleasedColor: "#306d30"
                    shadowPressedColor: "#B32D00"
                    releasedColor: "#499149"
                    pressedColor: "#306d30"
                    onClicked: {
                        walletManager.stopMining()
                        update()
                    }
                }
            }

            Text {
                id: statusText
                text: qsTr("Status: not mining")
                textFormat: Text.RichText
                wrapMode: Text.Wrap
            }
        }
    }

    function updateStatusText() {
        var text = ""
        if (walletManager.isMining()) {
            if (text !== "")
                text += "<br>";
            text += qsTr("Mining at %1 H/s").arg(walletManager.miningHashRate())
        }
        if (text === "") {
            text += qsTr("Not mining") + translationManager.emptyString;
        }
        statusText.text = text
    }

    function update() {
        updateStatusText()
        startSoloMinerButton.enabled = !walletManager.isMining()
        stopSoloMinerButton.enabled = !startSoloMinerButton.enabled
    }

    StandardDialog {
        id: errorPopup
        cancelVisible: false
    }

    Timer {
        id: timer
        interval: 2000; running: false; repeat: true
        onTriggered: update()
    }

    function onPageCompleted() {
        console.log("Mining page loaded");

        poolDropdown.dataModel = poolModel;
        poolDropdown.currentIndex = 0
        poolDropdown.update()

        update()
        timer.running = isDaemonLocal()

    }
    function onPageClosed() {
        timer.running = false
    }
}
