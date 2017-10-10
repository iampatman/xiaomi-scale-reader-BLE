//
//  MiScaleViewController.swift
//  BLE
//
//  Created by Nguyen Bui An Trung on 6/10/17.
//  Copyright © 2017 Nguyen Bui An Trung. All rights reserved.
//

import UIKit
import CoreBluetooth
import QuartzCore


import CoreBluetooth
import QuartzCore


let WEIGHT_MEASUREMENT_INDICATOR_CHAR = "2A9D"
let WEIGH_SCALE_SERVICE = "181D"

class MiScaleViewController: UIViewController {
	var device: CBPeripheral?
	var centralManager: CBCentralManager?
	
	
	@IBOutlet weak var txtWeight: UILabel!
	@IBOutlet weak var txtConnectionStatus: UILabel!

	override func viewDidAppear(_ animated: Bool) {
		startScanning()
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()

		
	}
	
	func startScanning(){
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


extension MiScaleViewController: CBCentralManagerDelegate  {
	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		print("didConnect peripheral")
		peripheral.discoverServices(nil)
		peripheral.delegate = self
		print(peripheral.state == .connected ? "Connected" : "Not connected")
	}
	
	
	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		print("didDiscover peripheral")
		print("Signal strength: \(RSSI)")
		if peripheral.identifier.uuidString != "1C9C427C-6039-4455-A973-405D28655412" {
			print("not MI scale")
			return
		}
		print("New device discovered")
		guard let name = peripheral.name  else {
			return
		}
		print(name)
		print(peripheral.identifier.uuidString)
		self.txtConnectionStatus.text = "Status: Connected"
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

extension MiScaleViewController: CBPeripheralDelegate{
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		print("didDiscoverServices")
		peripheral.services?.forEach {
			print("Service discovered: \($0.uuid)")
			peripheral.discoverCharacteristics(nil, for: $0)
		}
	}
	
	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		service.characteristics?.forEach({ (char) in
			print("Characteristic discovered: \(char.uuid.uuidString) \(char.uuid)")
			if char.uuid.uuidString.isEqual(WEIGHT_MEASUREMENT_INDICATOR_CHAR){
				peripheral.readValue(for: char)
				peripheral.setNotifyValue(true, for: char)
			}
		})
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		print("didUpdateValueFor")
		print(characteristic.uuid.uuidString)
		if (characteristic.uuid.uuidString.isEqual(WEIGHT_MEASUREMENT_INDICATOR_CHAR)){
			guard let data = characteristic.value  else {
				return
			}
			var byte: UInt16 = 0

			let array = data.withUnsafeBytes {
				[UInt8](UnsafeBufferPointer(start: $0, count: data.count))
			}
			print(array)
			let bytes: [UInt8] = [array[1], array[2]]
			let u16 = UnsafePointer(bytes).withMemoryRebound(to: UInt16.self, capacity: 1) {
				$0.pointee
			}
			print("u16: \(u16)") // u16: 513
			let x = Float(u16) / 200.0
			self.txtWeight.text = "\(x) kg"
		}
	}
	
}

