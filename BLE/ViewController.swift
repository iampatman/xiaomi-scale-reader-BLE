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


let DEVICE_INFO_SERVICE = "0x180A"

let MANUFACTURER_NAME_CHARACTERISTIC_UUID = "2A29"
class ViewController: UIViewController {
	var device: CBPeripheral?
	var centralManager: CBCentralManager?
	override func viewDidLoad() {
		super.viewDidLoad()
		let services: [CBUUID] = [CBUUID(string: DEVICE_INFO_SERVICE)]
		let centralManager = CBCentralManager(delegate: self, queue: nil)
		centralManager.scanForPeripherals(withServices: nil, options: nil)
		//centralManager.scanForPeripherals(withServices: services, options: nil)
		self.centralManager = centralManager
		
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func getMacnufacturer(fromCharacteristic characteristic: CBCharacteristic){
		guard let value = characteristic.value else {
			return;
		}
		
		let name: String = String(data: value, encoding: String.Encoding.utf8)!
		print(name)
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
		print(RSSI)
		guard let name = peripheral.name  else {
			return
		}
		print(name)
		//let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
		//print(name!)
		
		central.connect(peripheral, options: nil)
		peripheral.delegate = self
		device = peripheral
		central.stopScan()
//
//		if (name?.characters.count)! > 0 {
//			central.connect(peripheral, options: nil)
//		}
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
			print("Characteristic discovered: \(char.uuid.uuidString)")
			if char.uuid.uuidString.isEqual(MANUFACTURER_NAME_CHARACTERISTIC_UUID){
				peripheral.readValue(for: char)
				//peripheral.setNotifyValue(true, for: char)
			}
		})
	}
	
	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		print("didUpdateValueFor")

		if (characteristic.uuid.uuidString.isEqual(MANUFACTURER_NAME_CHARACTERISTIC_UUID)){
			getMacnufacturer(fromCharacteristic: characteristic)
		}
	}
	
}
