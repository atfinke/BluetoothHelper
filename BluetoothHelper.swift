//
//  BluetoothHelper.swift
//
//  Created by Andrew Finke on 8/11/15.
//  Copyright (c) 2015 Andrew Finke. All rights reserved.
//
//  Used http://pestohacks.blogspot.it/2012/07/make-osx-talks-with-bluetooth-gps.html as a guide


import Cocoa
import IOBluetooth

protocol BluetoothHelperProtocol {
    func bluetoothHelperChannelAlmostReady()
    func bluetoothHelperFailedToStartChannel()
    func bluetoothHelperReceivedString(string: String)
}

class BluetoothHelper: NSObject {
    
    private var address: String!
    
    private var comDevice: IOBluetoothDevice?
    private var comChannel: IOBluetoothRFCOMMChannel!
    
    var delegate: BluetoothHelperProtocol?
    
    init(deviceAddress: String) {
        super.init()
        address = deviceAddress
        IOBluetoothDeviceInquiry(delegate: self).start()
    }
    
    func deviceInquiryComplete(sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
        if let comDevice = comDevice {
            println("Bluetooth Helper: Found Correct Device (\(comDevice.name))")
            if let rfChannelID = findChannelID() {
                println("Bluetooth Helper: Found Channel")
                var channel: IOBluetoothRFCOMMChannel? = IOBluetoothRFCOMMChannel()
                if comDevice.openRFCOMMChannelAsync(&channel, withChannelID: rfChannelID, delegate: self) == kIOReturnSuccess {
                    println("Bluetooth Helper: Started to Open Channel")
                    comChannel = channel!
                }
                else {
                    println("Bluetooth Helper: Failed To Open Channel")
                    delegate?.bluetoothHelperFailedToStartChannel()
                }
            }
            else {
                println("Bluetooth Helper: Failed To Open Channel")
                delegate?.bluetoothHelperFailedToStartChannel()
            }
        }
        else {
            println("Bluetooth Helper: Failed To Open Channel")
            delegate?.bluetoothHelperFailedToStartChannel()
        }
    }
    
    func sendMessage(string: NSString) {
        println("Bluetooth Helper: Sending Message (\(string))")
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        comChannel?.writeSync(UnsafeMutablePointer(data.bytes), length: UInt16(data.length))
    }
    
    private func findChannelID() -> BluetoothRFCOMMChannelID? {
        println("Bluetooth Helper: Finding Channel ID")
        let services = comDevice!.services as! [IOBluetoothSDPServiceRecord]
        var newChannel = BluetoothRFCOMMChannelID()
        for service in services {
            if service.getRFCOMMChannelID(&newChannel) == kIOReturnSuccess {
                return newChannel
            }
        }
        return nil
    }
    
    func deviceInquiryDeviceFound(sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
        if device.addressString == address {
            comDevice = device
            sender.stop()
        }
        else {
            println("Bluetooth Helper: Found Other Device (\(device.name): \(device.addressString))")
        }
    }
    
    func rfcommChannelOpenComplete(rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
        println("Bluetooth Helper: Channel Almost Ready")
        delegate?.bluetoothHelperChannelAlmostReady()
    }
    
    func rfcommChannelData(rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutablePointer<Void>, length dataLength: Int) {
        if let dataString = NSString(data: NSData(bytes: dataPointer, length: dataLength), encoding: NSUTF8StringEncoding) as? String {
            delegate?.bluetoothHelperReceivedString(dataString)
        }
    }
}
