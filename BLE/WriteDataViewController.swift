//
//  WriteDataViewController.swift
//  BLE
//
//  Created by Nguyen Bui An Trung on 3/10/17.
//  Copyright © 2017 Nguyen Bui An Trung. All rights reserved.
//

import UIKit
import HealthKit

class WriteDataViewController: UITableViewController {

	
	@IBOutlet weak var txtBloodGlucose: UITextField!
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

	
	@IBAction func saveValue(){
		guard let value = Double.init(txtBloodGlucose.text!) else {
			return;
		}
		txtBloodGlucose.text = ""
		saveBloodGlucoseSample(bloodGlucose: value, date: Date())

	}
	
	func saveBloodGlucoseSample(bloodGlucose: Double, date: Date) {
  
		//1.  Make sure the body mass type exists
		guard let bodyMassIndexType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose) else {
			fatalError("Blood Gluclose Type is no longer available in HealthKit")
		}
		
		//2.  Use the Count HKUnit to create a body mass quantity
		//let milligramPerDeciLiter = HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci))
		let mmolpLUnit = HKUnit.moleUnit(with: HKMetricPrefix.milli,
		                                molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: HKUnit.liter())
		let bloogGlucoseQuantity = HKQuantity(unit: mmolpLUnit,
                                    doubleValue: bloodGlucose)
		
		let bloodGlucoseSample = HKQuantitySample(type: bodyMassIndexType,
                                             quantity: bloogGlucoseQuantity,
                                             start: date,
                                             end: date)
		
		//3.  Save the same to HealthKit
		HKHealthStore().save(bloodGlucoseSample) { (success, error) in
			
			if let error = error {
				print("Error Saving Blood Glucose Sample: \(error.localizedDescription)")
			} else {
				print("Successfully saved Blood Glucose Sample")
				DispatchQueue.main.async {
					let alert = UIAlertController(title: "Success", message: "Saved Successfully", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
					self.present(alert, animated: true, completion: nil)
				}
				
			}
		}
	}
	



}
