//
//  HealthKitAssistant.swift
//  BLE
//
//  Created by Nguyen Bui An Trung on 28/9/17.
//  Copyright © 2017 Nguyen Bui An Trung. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitAssistant {
	
	
	private enum HealthkitSetupError: Error {
		case notAvailableOnDevice
		case dataTypeNotAvailable
	}
	
	class func authorizeHealthKit(completion: @escaping (Bool) -> Void){
		//1. Check to see if HealthKit Is Available on this device
		guard HKHealthStore.isHealthDataAvailable() else {
			completion(false)
			return
		}
		
		//2. Prepare the data types that will interact with HealthKit
	
		guard   let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
			let bloodType = HKObjectType.characteristicType(forIdentifier: .bloodType),
			let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex),
			let bloodGlucose = HKObjectType.quantityType(forIdentifier: .bloodGlucose),
			let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
			let height = HKObjectType.quantityType(forIdentifier: .height),
			let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
			let steps = HKObjectType.quantityType(forIdentifier: .stepCount),
			let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
			let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
			
				completion(false)
				return
		}
		
		let healthKitTypesToWrite: Set<HKSampleType> = [bodyMassIndex,
		                                                activeEnergy,
		                                                bloodGlucose,
		                                                HKObjectType.workoutType()]
		
		let healthKitTypesToRead: Set<HKObjectType> = [dateOfBirth,
		                                               bloodType,
		                                               biologicalSex,
		                                               bodyMassIndex,
		                                               height,
		                                               steps,
		                                               bodyMass,
		                                               distance,
		                                               HKObjectType.workoutType()]
		//4. Request Authorization
		HKHealthStore().requestAuthorization(toShare: healthKitTypesToWrite,
		                                     read: healthKitTypesToRead) { (success, error) in
												completion(success)
		}

	}
	
	class func getMostRecentSample(for sampleType: HKSampleType,
	                               completion: @escaping (HKQuantitySample?, Error?) -> Void) {
  
		//1. Use HKQuery to load the most recent samples.
		let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
		                                                      end: Date(),
		                                                      options: .strictEndDate)
		
		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
		                                      ascending: false)
		
		let limit = 1
		
		let sampleQuery = HKSampleQuery(sampleType: sampleType,
		                                predicate: mostRecentPredicate,
		                                limit: limit,
		                                sortDescriptors: [sortDescriptor]) { (query, samples, error) in
											
											//2. Always dispatch to the main thread when complete.
											DispatchQueue.main.async {
												
												guard let samples = samples,
													let mostRecentSample = samples.first as? HKQuantitySample else {
														
														completion(nil, error)
														return
												}
												
												completion(mostRecentSample, nil)
											}
  }
		
		HKHealthStore().execute(sampleQuery)
	}

}
