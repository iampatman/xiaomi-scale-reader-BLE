//
//  ViewController.swift
//  BLE
//
//  Created by Nguyen Bui An Trung on 19/9/17.
//  Copyright © 2017 Nguyen Bui An Trung. All rights reserved.
//

import UIKit
import CoreBluetooth
import QuartzCore



let DEVICE_INFO_SERVICE = "180A"

let MANUFACTURER_NAME_CHARACTERISTIC_UUID = "2A29"
class ViewController: UIViewController {
	var device: CBPeripheral?
	var centralManager: CBCentralManager?
	override func viewDidLoad() {
		super.viewDidLoad()
		let services: [CBUUID] = [CBUUID(string: DEVICE_INFO_SERVICE)]
		let centralManager = CBCentralManager(delegate: self, queue: nil)
		centralManager.scanForPeripherals(withServices: nil, options: nil)
		self.centralManager = centralManager
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	func getMacnufacturer(fromCharacteristic characteristic: CBCharacteristic){
		guard let value = characteristic.value else {
			return;
		}
		
		let name: String = String(data: value, encoding: String.Encoding.utf8)!
		print("Manufacturere: \(name)")
	}
}


extension ViewController: CBCentralManagerDelegate  {
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		print("didConnect peripheral")
		peripheral.discoverServices(nil)
		peripheral.delegate = self
		print(peripheral.state == .connected ? "Connected" : "Not connected")
	}
	

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		print("didDiscover peripheral")
		print("Signal strength: \(RSSI)")
		if peripheral.identifier.uuidString != "B833F637-E241-4A0A-BD4A-1A727EDB0267" {
			print("not MI")
			return
		}
		print("New device discovered")
		guard let name = peripheral.name  else {
			return
		}
		print(name)
		print(peripheral.identifier.uuidString)
		central.connect(peripheral, options: nil)
		peripheral.delegate = self
		central.stopScan()
		self.device = peripheral
//		central.stopScan()

	}
	
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		switch central.state {
		case .poweredOn:
			print("powered on")
			central.scanForPeripherals(withServices: nil, options: nil)
			break;
		case .unauthorized:
			print("unauthorized")
			break;
		case .unsupported:
			print("unsupported")
			break;
		case .poweredOff:
			print("poweredOff")
			break;
		default:
			print("Unkonwoed state")
		}
	}
	

}

extension ViewController: CBPeripheralDelegate{
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		print("didDiscoverServices")
		peripheral.services?.forEach {
			print("Service discovered: \($0.uuid)")
			peripheral.discoverCharacteristics(nil, for: $0)
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		print("didDiscoverCharacteristicsFor")
		service.characteristics?.forEach({ (char) in
			
			print("Characteristic discovered: \(char.uuid.uuidString) \(char.uuid)")
			if char.uuid.uuidString.isEqual("FF0C"){
				peripheral.readValue(for: char)
				peripheral.setNotifyValue(true, for: char)
			}
		})
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		print("didUpdateValueFor")
		print(characteristic.uuid.uuidString)
		if (characteristic.uuid.uuidString.isEqual("FF0C")){
			
			
			guard let data = characteristic.value  else {
				return
			}
			var byte: UInt16 = 0

			//data.copyBytes(to: &byte, from: 1)
			//let x = [UInt16] (characteristic.value!)
//			print(x)
			let array = data.withUnsafeBytes {
				[UInt8](UnsafeBufferPointer(start: $0, count: data.count))
			}
			print(array)
			
			
		}
	}
	
}


//protocol DataConvertible {
//	init(data:Data)
//	var data:Data { get }
//}
//
//extension DataConvertible {
//	init(data:Data) {
//		guard data.count == MemoryLayout<Self>.size else {
//			fatalError("data size (\(data.count)) != type size (\(MemoryLayout<Self>.size))")
//		}
//		self = data.withUnsafeBytes { $0.pointee }
//	}
//	
//	var data:Data {
//		var value = self
//		return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
//	}
//}
//
//extension UInt8:DataConvertible {}
//extension UInt16:DataConvertible {}
//extension UInt32:DataConvertible {}
//extension Int32:DataConvertible {}
//extension Int64:DataConvertible {}
//extension Double:DataConvertible {}
//extension Float:DataConvertible {}
