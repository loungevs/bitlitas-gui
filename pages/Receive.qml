// Copyright (c) 2018, Bitlitas
// All rights reserved. Based on Monero.

import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

import "../components"
import bitlitasComponents.Clipboard 1.0
import bitlitasComponents.Wallet 1.0
import bitlitasComponents.WalletManager 1.0
import bitlitasComponents.TransactionHistory 1.0
import bitlitasComponents.TransactionHistoryModel 1.0

Rectangle {

    color: "#F0EEEE"
    property alias addressText : addressLine.text
    property alias paymentIdText : paymentIdLine.text
    property alias integratedAddressText : integratedAddressLine.text
    property var model
    property string trackingLineText: ""

    function updatePaymentId(payment_id) {
        if (typeof appWindow.currentWallet === 'undefined' || appWindow.currentWallet == null)
            return

        // generate a new one if not given as argument
        if (typeof payment_id === 'undefined') {
            payment_id = appWindow.currentWallet.generatePaymentId()
            paymentIdLine.text = payment_id
        }

        if (payment_id.length > 0) {
            integratedAddressLine.text = appWindow.currentWallet.integratedAddress(payment_id)
            if (integratedAddressLine.text === "") {
                integratedAddressLine.text = qsTr("Invalid payment ID")
                paymentIdLine.error = true
            }
            else {
                paymentIdLine.error = false
            }
        }
        else {
            paymentIdLine.text = ""
            integratedAddressLine.text = ""
            paymentIdLine.error = false
        }

        update()
    }

    function makeQRCodeString() {
        var s = "bitlitas:"
        var nfields = 0
        s += addressLine.text
        var amount = amountLine.text.trim()
        if (amount !== "") {
          s += (nfields++ ? "&" : "?")
          s += "tx_amount=" + amount
        }
        var pid = paymentIdLine.text.trim().toLowerCase()
        if (pid !== "" && walletManager.paymentIdValid(pid)) {
          s += (nfields++ ? "&" : "?")
          s += "tx_payment_id=" + pid
        }
        return s
    }

    function setTrackingLineText(text) {
        // don't replace with same text, it wrecks selection while the user is selecting
        // also keep track of text, because when we read back the text from the widget,
        // we do not get what we put it, but some extra HTML stuff on top
        if (text != trackingLineText) {
            trackingLine.text = text
            trackingLineText = text
        }
    }

    function update() {
        if (!appWindow.currentWallet) {
            setTrackingLineText("-")
            return
        }
        if (appWindow.currentWallet.connected() == Wallet.ConnectionStatus_Disconnected) {
            setTrackingLineText(qsTr("WARNING: no connection to daemon"))
            return
        }

        var model = appWindow.currentWallet.historyModel
        var count = model.rowCount()
        var totalAmount = 0
        var nTransactions = 0
        var list = ""
        var blockchainHeight = 0
        for (var i = 0; i < count; ++i) {
            var idx = model.index(i, 0)
            var isout = model.data(idx, TransactionHistoryModel.TransactionIsOutRole);
            var payment_id = model.data(idx, TransactionHistoryModel.TransactionPaymentIdRole);
            if (!isout && payment_id == paymentIdLine.text) {
                var amount = model.data(idx, TransactionHistoryModel.TransactionAtomicAmountRole);
                totalAmount = walletManager.addi(totalAmount, amount)
                nTransactions += 1

                var txid = model.data(idx, TransactionHistoryModel.TransactionHashRole);
                var blockHeight = model.data(idx, TransactionHistoryModel.TransactionBlockHeightRole);
                if (blockHeight == 0) {
                    list += qsTr("in the txpool: %1").arg(txid) + translationManager.emptyString
                } else {
                    if (blockchainHeight == 0)
                        blockchainHeight = walletManager.blockchainHeight()
                    var confirmations = blockchainHeight - blockHeight - 1
                    var displayAmount = model.data(idx, TransactionHistoryModel.TransactionDisplayAmountRole);
                    if (confirmations > 1) {
                        list += qsTr("%2 confirmations: %3 (%1)").arg(txid).arg(confirmations).arg(displayAmount) + translationManager.emptyString
                    } else {
                        list += qsTr("1 confirmation: %2 (%1)").arg(txid).arg(displayAmount) + translationManager.emptyString
                    }
                }
                list += "<br>"
            }
        }

        if (nTransactions == 0) {
            setTrackingLineText(qsTr("No transaction found yet...") + translationManager.emptyString)
            return
        }

        var text = ((nTransactions == 1) ? qsTr("Transaction found") : qsTr("%1 transactions found").arg(nTransactions)) + translationManager.emptyString

        var expectedAmount = walletManager.amountFromString(amountLine.text)
        if (expectedAmount && expectedAmount != amount) {
            var displayTotalAmount = walletManager.displayAmount(totalAmount)
            if (amount > expectedAmount) {
                text += qsTr(" with more money (%1)").arg(displayTotalAmount) + translationManager.emptyString
            } else if (amount < expectedAmount) {
                text += qsTr(" with not enough money (%1)").arg(displayTotalAmount) + translationManager.emptyString
            }
        }

        setTrackingLineText(text + "<br>" + list)
    }

    Clipboard { id: clipboard }


    /* main layout */
    ColumnLayout {
        id: mainLayout
        anchors.margins: (isMobile)? 17 : 40
        anchors.topMargin: 40 * scaleRatio

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right

        spacing: 20 * scaleRatio
        property int labelWidth: 120 * scaleRatio
        property int editWidth: 400 * scaleRatio
        property int lineEditFontSize: 12 * scaleRatio
        property int qrCodeSize: 240 * scaleRatio


        ColumnLayout {
            id: addressRow
            Label {
                id: addressLabel
                text: qsTr("Address") + translationManager.emptyString
                width: mainLayout.labelWidth
            }

            LineEdit {
                id: addressLine
                fontSize: mainLayout.lineEditFontSize
                placeholderText: qsTr("ReadOnly wallet address displayed here") + translationManager.emptyString;
                readOnly: true
                width: mainLayout.editWidth
                Layout.fillWidth: true
                onTextChanged: cursorPosition = 0

                IconButton {
                    imageSource: "../images/copyToClipboard.png"
                    onClicked: {
                        if (addressLine.text.length > 0) {
                            console.log(addressLine.text + " copied to clipboard")
                            clipboard.setText(addressLine.text)
                            appWindow.showStatusMessage(qsTr("Address copied to clipboard"),3)
                        }
                    }
                }
            }
        }

        GridLayout {
            id: paymentIdRow
            columns:2
            Label {
                Layout.columnSpan: 2
                id: paymentIdLabel
                text: qsTr("Payment ID") + translationManager.emptyString
                width: mainLayout.labelWidth
            }


            LineEdit {
                id: paymentIdLine
                fontSize: mainLayout.lineEditFontSize
                placeholderText: qsTr("16 hexadecimal characters") + translationManager.emptyString;
                readOnly: false
                onTextChanged: updatePaymentId(paymentIdLine.text)

                width: mainLayout.editWidth
                Layout.fillWidth: true

                IconButton {
                    imageSource: "../images/copyToClipboard.png"
                    onClicked: {
                        if (paymentIdLine.text.length > 0) {
                            clipboard.setText(paymentIdLine.text)
                            appWindow.showStatusMessage(qsTr("Payment ID copied to clipboard"),3)
                        }
                    }
                }
            }

            StandardButton {
                id: generatePaymentId
                shadowReleasedColor: "#306d30"
                shadowPressedColor: "#B32D00"
                releasedColor: "#499149"
                pressedColor: "#306d30"
                text: qsTr("Generate") + translationManager.emptyString;
                onClicked: updatePaymentId()
            }

            StandardButton {
                id: clearPaymentId
                enabled: !!paymentIdLine.text
                shadowReleasedColor: "#306d30"
                shadowPressedColor: "#B32D00"
                releasedColor: "#499149"
                pressedColor: "#306d30"
                text: qsTr("Clear") + translationManager.emptyString;
                onClicked: updatePaymentId("")
            }
        }
         
        ColumnLayout {
            id: integratedAddressRow
            Label {
                id: integratedAddressLabel
                text: qsTr("Integrated address") + translationManager.emptyString
                width: mainLayout.labelWidth
            }


            LineEdit {

                id: integratedAddressLine
                fontSize: mainLayout.lineEditFontSize
                placeholderText: qsTr("Generate payment ID for integrated address") + translationManager.emptyString
                readOnly: true
                width: mainLayout.editWidth
                Layout.fillWidth: true

                onTextChanged: cursorPosition = 0

                IconButton {
                    imageSource: "../images/copyToClipboard.png"
                    onClicked: {
                        if (integratedAddressLine.text.length > 0) {
                            clipboard.setText(integratedAddressLine.text)
                            appWindow.showStatusMessage(qsTr("Integrated address copied to clipboard"),3)
                        }
                    }
                }

            }
        }

        ColumnLayout {
            id: amountRow
            Label {
                id: amountLabel
                text: qsTr("Amount") + translationManager.emptyString
                width: mainLayout.labelWidth
            }


            LineEdit {
                id: amountLine
                fontSize: mainLayout.lineEditFontSize
                placeholderText: qsTr("Amount to receive") + translationManager.emptyString
                readOnly: false
                width: mainLayout.editWidth
                Layout.fillWidth: true
                validator: DoubleValidator {
                    bottom: 0.0
                    top: 18446744.073709551615
                    decimals: 12
                    notation: DoubleValidator.StandardNotation
                    locale: "C"
                }
            }
        }

        RowLayout {
            id: trackingRow
            visible: !isAndroid && !isIOS
            Label {
                id: trackingLabel
                textFormat: Text.RichText
                text: "<style type='text/css'>a {text-decoration: none; color: #499149; font-size: 14px;}</style>" +
                      qsTr("Tracking") +
                      "<font size='2'> (</font><a href='#'>" +
                      qsTr("help") +
                      "</a><font size='2'>)</font>" +
                      translationManager.emptyString
                width: mainLayout.labelWidth
                onLinkActivated: {
                    trackingHowToUseDialog.title  = qsTr("Tracking payments") + translationManager.emptyString;
                    trackingHowToUseDialog.text = qsTr(
                        "<p><font size='+2'>This is a simple sales tracker:</font></p>" +
                        "<p>Click Generate to create a random payment id for a new customer</p> " +
                        "<p>Let your customer scan that QR code to make a payment (if that customer has software which " +
                        "supports QR code scanning).</p>" +
                        "<p>This page will automatically scan the blockchain and the tx pool " +
                        "for incoming transactions using this QR code. If you input an amount, it will also check " +
                        "that incoming transactions total up to that amount.</p>" +
                        "It's up to you whether to accept unconfirmed transactions or not. It is likely they'll be " +
                        "confirmed in short order, but there is still a possibility they might not, so for larger " +
                        "values you may want to wait for one or more confirmation(s).</p>"
                    )
                    trackingHowToUseDialog.icon = StandardIcon.Information
                    trackingHowToUseDialog.open()
                }
            }

            TextEdit {
                id: trackingLine
                anchors.top: trackingRow.top + 25
                textFormat: Text.RichText
                text: ""
                readOnly: true
                width: mainLayout.editWidth
                Layout.fillWidth: true
                selectByMouse: true
            }

        }

        MessageDialog {
            id: trackingHowToUseDialog
            standardButtons: StandardButton.Ok
        }

        FileDialog {
            id: qrFileDialog
            title: "Please choose a name"
            folder: shortcuts.pictures
            selectExisting: false
            nameFilters: [ "Image (*.png)"]
            onAccepted: {
                if( ! walletManager.saveQrCode(makeQRCodeString(), walletManager.urlToLocalPath(fileUrl))) {
                    console.log("Failed to save QrCode to file " + walletManager.urlToLocalPath(fileUrl) )
                    trackingHowToUseDialog.title  = qsTr("Save QrCode") + translationManager.emptyString;
                    trackingHowToUseDialog.text = qsTr("Failed to save QrCode to ") + walletManager.urlToLocalPath(fileUrl) + translationManager.emptyString;
                    trackingHowToUseDialog.icon = StandardIcon.Error
                    trackingHowToUseDialog.open()
                }
            }
        }
        ColumnLayout {
            Menu {
                id: qrMenu
                title: "QrCode"
                MenuItem {
                   text: qsTr("Save As") + translationManager.emptyString;
                   onTriggered: qrFileDialog.open()
                }
            }

            Image {
                id: qrCode
                anchors.margins: 50 * scaleRatio
                Layout.fillWidth: true
                Layout.minimumHeight: mainLayout.qrCodeSize
                smooth: false
                fillMode: Image.PreserveAspectFit
                source: "image://qrcode/" + makeQRCodeString()
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        if (mouse.button == Qt.RightButton)
                            qrMenu.popup()
                    }
                    onPressAndHold: qrFileDialog.open()
                }
            }
        }
    }

    Timer {
        id: timer
        interval: 2000; running: false; repeat: true
        onTriggered: update()
    }

    function onPageCompleted() {
        console.log("Receive page loaded");

        if (appWindow.currentWallet) {
            if (addressLine.text.length === 0 || addressLine.text !== appWindow.currentWallet.address) {
                addressLine.text = appWindow.currentWallet.address
            }
        }

        update()
        timer.running = true
    }

    function onPageClosed() {
        timer.running = false
    }
}