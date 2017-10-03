//
//  HealthDataViewController.swift
//  BLE
//
//  Created by Nguyen Bui An Trung on 28/9/17.
//  Copyright © 2017 Nguyen Bui An Trung. All rights reserved.
//

import UIKit

import HealthKit
import HealthKitUI

class HealthDataViewController: UITableViewController {
	
	
	@IBOutlet weak var lblAge: UILabel!
	@IBOutlet weak var lblSex: UILabel!
	@IBOutlet weak var lblBloodType: UILabel!
	@IBOutlet weak var lblStepCount: UILabel!
	@IBOutlet weak var lblDistance: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		HealthKitAssistant.authorizeHealthKit { (success) in
			print(success)
		}
		do {
			try readData()
		} catch {
			print (error.localizedDescription)
		}
		saveBodyMassIndexSample(bodyMassIndex: 21, date: Date())
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	@IBAction func loadHealthKitData(){
		do {
			let result = try readData()
			self.lblAge.text = "\(result.age) years old"
			self.lblSex.text = "\(result.biologicalSex.stringRepresentation)"
			self.lblBloodType.text = "\(result.bloodType.stringRepresentation)"
			DispatchQueue.global().async {
				self.loadStepsData(completion: { (steps, error) in
					DispatchQueue.main.async {
						self.lblStepCount.text = "\(steps) steps"
						print(steps)

					}
					
				})
				
				self.loadDistanceData(completion: { (distance, error) in
					DispatchQueue.main.async {
						let d = String(format: "%.02f", distance)

						self.lblDistance.text = "\(d) m"
						print(distance)
					}


				})

			}
			} catch {
			print (error.localizedDescription)
		}
	}
	
	func readData() throws -> (age: Int,
	                biologicalSex: HKBiologicalSex,
	                bloodType: HKBloodType){
		let healthKitStore = HKHealthStore()
		
		do {
	
	//1. This method throws an error if these data are not available.
			let birthdayComponents =  try healthKitStore.dateOfBirthComponents()
			let biologicalSex =       try healthKitStore.biologicalSex()
			let bloodType =           try healthKitStore.bloodType()
	
			//2. Use Calendar to calculate age.
			let today = Date()
			let calendar = Calendar.current
			let todayDateComponents = calendar.dateComponents([.year],
	                                                  from: today)
			let thisYear = todayDateComponents.year!
			let age = thisYear - birthdayComponents.year!
	
			//3. Unwrap the wrappers to get the underlying enum values.
			let unwrappedBiologicalSex = biologicalSex.biologicalSex
			let unwrappedBloodType = bloodType.bloodType
			
			return (age, unwrappedBiologicalSex, unwrappedBloodType)
			
		}
	}
	
	
	func loadStepsData(completion: @escaping (Double, Error?) -> ()){
		let type = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)


		let healthKitStore = HKHealthStore()

		// Our search predicate which will fetch data from now until a day ago
		// (Note, 1.day comes from an extension
		// You'll want to change that to your own NSDate
		//   Get the start of the day
		let date = Date()
		let cal = Calendar(identifier: Calendar.Identifier.gregorian)
		let newDate = cal.startOfDay(for: date)
		
		let predicate = HKQuery.predicateForSamples(withStart: newDate, end: Date(), options: HKQueryOptions.strictStartDate)
	
		// The actual HealthKit Query which will fetch all of the steps and sub them up for us.
		let query = HKSampleQuery(sampleType: type!, predicate: predicate, limit: 0, sortDescriptors: nil) { query, results, error in
			var steps: Double = 0
	
			if (results?.count)! > 0
				{
					for result in results as! [HKQuantitySample] {
						steps += result.quantity.doubleValue(for: HKUnit.count())
					}
				}
	
			completion(steps, error)
		}
		
		healthKitStore.execute(query)
	}
	
	func loadDistanceData(completion: @escaping (Double, Error?) -> ()){
		let type = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
		
		
		let healthKitStore = HKHealthStore()
		
		// Our search predicate which will fetch data from now until a day ago
		// (Note, 1.day comes from an extension
		// You'll want to change that to your own NSDate
		//   Get the start of the day
		let date = Date()
		let cal = Calendar(identifier: Calendar.Identifier.gregorian)
		let newDate = cal.startOfDay(for: date)
		
		let predicate = HKQuery.predicateForSamples(withStart: newDate, end: Date(), options: HKQueryOptions.strictStartDate)
		
		// The actual HealthKit Query which will fetch all of the steps and sub them up for us.
		let query = HKSampleQuery(sampleType: type!, predicate: predicate, limit: 0, sortDescriptors: nil) { query, results, error in
			var distance: Double = 0
			
			if (results?.count)! > 0
			{
				for result in results as! [HKQuantitySample] {
					distance += result.quantity.doubleValue(for: HKUnit.meter())
				}
			}
			
			completion(distance, error)
		}
		
		healthKitStore.execute(query)
	}
	
	
	func saveBodyMassIndexSample(bodyMassIndex: Double, date: Date) {
  
		//1.  Make sure the body mass type exists
		guard let bodyMassIndexType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) else {
			fatalError("Body Mass Index Type is no longer available in HealthKit")
		}
		
		//2.  Use the Count HKUnit to create a body mass quantity
		let bodyMassQuantity = HKQuantity(unit: HKUnit.count(),
                                    doubleValue: bodyMassIndex)
		
		let bodyMassIndexSample = HKQuantitySample(type: bodyMassIndexType,
                                             quantity: bodyMassQuantity,
                                             start: date,
                                             end: date)
		
		//3.  Save the same to HealthKit
		HKHealthStore().save(bodyMassIndexSample) { (success, error) in
	
			if let error = error {
				print("Error Saving BMI Sample: \(error.localizedDescription)")
			} else {
				print("Successfully saved BMI Sample")
			}
		}
	}

}

extension Date {
	var yesterday: Date {
		return Calendar.current.date(byAdding: .day, value: -1, to: self)!
	}
	var tomorrow: Date {
		return Calendar.current.date(byAdding: .day, value: 1, to: self)!
	}
	var noon: Date {
		return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
	}
	var month: Int {
		return Calendar.current.component(.month,  from: self)
	}
	var isLastDayOfMonth: Bool {
		return tomorrow.month != month
	}
}
