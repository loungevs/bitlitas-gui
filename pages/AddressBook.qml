// Copyright (c) 2018, Bitlitas
// All rights reserved. Based on Monero.

import QtQuick 2.0
import QtQuick.Layouts 1.1
import "../components"
import bitlitasComponents.AddressBook 1.0
import bitlitasComponents.AddressBookModel 1.0

Rectangle {
    id: root
    color: "#F0EEEE"
    property var model

    ColumnLayout {
        anchors.margins: 17 * scaleRatio
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        spacing: 10 * scaleRatio

        Label {
            id: addressLabel
            anchors.left: parent.left
            text: qsTr("Address") + translationManager.emptyString
        }

        RowLayout {
            StandardButton {
                id: qrfinderButton
                text: qsTr("Qr Code") + translationManager.emptyString
                shadowReleasedColor: "#306d30"
                shadowPressedColor: "#B32D00"
                releasedColor: "#499149"
                pressedColor: "#306d30"
                visible : appWindow.qrScannerEnabled
                enabled : visible
                width: visible ? 60 * scaleRatio : 0
                onClicked: {
                    cameraUi.state = "Capture"
                    cameraUi.qrcode_decoded.connect(updateFromQrCode)
                }
            }

            LineEdit {
                Layout.fillWidth: true;
                id: addressLine
                error: true;
                placeholderText: qsTr("4...") + translationManager.emptyString
            }
        }

        Label {
            id: paymentIdLabel
            text: qsTr("Payment ID") + translationManager.emptyString
            tipText: qsTr("<b>Payment ID</b><br/><br/>A unique user name used in<br/>the address book. It is not a<br/>transfer of information sent<br/>during the transfer")
                    + translationManager.emptyString
        }

        LineEdit {
            id: paymentIdLine
            Layout.fillWidth: true;
            placeholderText: qsTr("Paste 64 hexadecimal characters") + translationManager.emptyString
        }

        Label {
            id: descriptionLabel
            text: qsTr("Description <font size='2'>(Optional)</font>") + translationManager.emptyString
        }

        LineEdit {
            id: descriptionLine
            Layout.fillWidth: true;
            placeholderText: qsTr("Give this entry a name or description") + translationManager.emptyString
        }


        RowLayout {
            id: addButton
            Layout.bottomMargin: 17 * scaleRatio
            StandardButton {
                shadowReleasedColor: "#306d30"
                shadowPressedColor: "#B32D00"
                releasedColor: "#499149"
                pressedColor: "#306d30"
                text: qsTr("Add") + translationManager.emptyString
                enabled: checkInformation(addressLine.text, paymentIdLine.text, appWindow.persistentSettings.testnet)

                onClicked: {
                    if (!currentWallet.addressBook.addRow(addressLine.text.trim(), paymentIdLine.text.trim(), descriptionLine.text)) {
                        informationPopup.title = qsTr("Error") + translationManager.emptyString;
                        // TODO: check currentWallet.addressBook.errorString() instead.
                        if(currentWallet.addressBook.errorCode() === AddressBook.Invalid_Address)
                             informationPopup.text  = qsTr("Invalid address") + translationManager.emptyString
                        else if(currentWallet.addressBook.errorCode() === AddressBook.Invalid_Payment_Id)
                             informationPopup.text  = currentWallet.addressBook.errorString()
                        else
                             informationPopup.text  = qsTr("Can't create entry") + translationManager.emptyString

                        informationPopup.onCloseCallback = null
                        informationPopup.open();
                    } else {
                        addressLine.text = "";
                        paymentIdLine.text = "";
                        descriptionLine.text = "";
                    }
                }
            }
        }

    }

    Rectangle {
        id: tableRect
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height - addButton.y - addButton.height - 36 * scaleRatio
        color: "#FFFFFF"

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.InQuad }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 1
            color: "#DBDBDB"
        }

        Scroll {
            id: flickableScroll
            anchors.right: table.right
            anchors.rightMargin: -14
            anchors.top: table.top
            anchors.bottom: table.bottom
            flickable: table
        }

        AddressBookTable {
            id: table
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            onContentYChanged: flickableScroll.flickableContentYChanged()
            model: root.model
        }
    }

    function checkInformation(address, payment_id, testnet) {
      address = address.trim()
      payment_id = payment_id.trim()

      var address_ok = walletManager.addressValid(address, testnet)
      var payment_id_ok = payment_id.length == 0 || walletManager.paymentIdValid(payment_id)
      var ipid = walletManager.paymentIdFromAddress(address, testnet)
      if (ipid.length > 0 && payment_id.length > 0)
         payment_id_ok = false

      addressLine.error = !address_ok
      paymentIdLine.error = !payment_id_ok

      return address_ok && payment_id_ok
    }

    function onPageCompleted() {
        console.log("adress book");
        root.model = currentWallet.addressBookModel;
    }

    function updateFromQrCode(address, payment_id, amount, tx_description, recipient_name) {
        console.log("updateFromQrCode")
        addressLine.text = address
        paymentIdLine.text = payment_id
        //amountLine.text = amount
        descriptionLine.text = recipient_name + " " + tx_description
        cameraUi.qrcode_decoded.disconnect(updateFromQrCode)
    }

}
