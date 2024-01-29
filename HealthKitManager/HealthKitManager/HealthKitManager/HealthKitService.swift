//
//  HealthKitService.swift
//  HealthKitManager
//
//  Created by Ahmed Fayek on 28/01/2024.
//

import RxSwift
import HealthKit
import UIKit

protocol HealthKitServiceProtocol {
    
    func getBloodGlucose(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
    
    func getStepsCount(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse>
    func getCalories(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse>
    func getDistance(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse>
    func getExerciseTime(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse>
    func requestAutharization(completion: @escaping (Bool) -> Void)
    func onPermissionDenied()
}

public final class HealthKitService: HealthKitServiceProtocol {
    let healthStore = HKHealthStore()
    

    func getBloodGlucose(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        readBloodGlucoseData(startDate: startDate, endDate: endDate) { result, error in
            completionHandler (result, error)
        }
    }

    func readBloodGlucoseData(startDate: Date, endDate: Date, completion: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        // Define the type of data you want to read (blood glucose)
        let bloodGlucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose)!
        var data: [[String: Any]] = []
        //Create the predicate
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let userEnteredPredicate = NSPredicate(format: "metadata.%K != NO", HKMetadataKeyWasUserEntered)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, userEnteredPredicate])
        // Create a sample query
        let query = HKSampleQuery(sampleType: bloodGlucoseType, predicate: compoundPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] (query, results, error) in
            if let bloodGlucoseSamples = results as? [HKQuantitySample] {
                // Process the blood glucose samples
                for sample in bloodGlucoseSamples {
                    if let bloodRead = self?.getBloodGlucoseFormatedResponse(sample: sample) {
                        data.append(bloodRead)
                    }
                }
                completion(data, nil)
            } else {
                completion(nil, "Error reading blood glucose data: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        // Execute the query
        HKHealthStore().execute(query)
    }
 
    func getBloodGlucoseFormatedResponse(sample: HKQuantitySample)-> [String: Any]? {
        let value = sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
        let date = sample.startDate
        print("Blood Glucose Value: \(value) mg/dL, Date: \(date)")
        return ["type": "Blood Glucose",
                "value": value,
                "unit": "mg/dL",
                "timestamp": date]
    }
    
    
    
    
    
    
    
    
    func getBloodGlucose(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse> {
        let stepsType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        let unit = HKUnit(from: "mg/dL")
        return getStatisticsResult(type: stepsType, unit: unit,
                              startDate: startDate, endDate: endDate, interval: interval)
    }

    func getStepsCount(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse> {
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let unit = HKUnit.count()
        return getStatisticsResult(type: stepsType, unit: unit,
                              startDate: startDate, endDate: endDate, interval: interval)
    }

    func getCalories(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse> {
        let energyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let unit = HKUnit.kilocalorie()
        return getStatisticsResult(type: energyBurnedType, unit: unit,
                              startDate: startDate, endDate: endDate, interval: interval)
    }

    func getDistance(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse> {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let unit = HKUnit.meter()
        return getStatisticsResult(type: distanceType, unit: unit,
                              startDate: startDate, endDate: endDate, interval: interval)
    }

    func getExerciseTime(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse> {
        let walkingSpeedType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        let unit = HKUnit.minute()
        return getStatisticsResult(type: walkingSpeedType, unit: unit,
                              startDate: startDate, endDate: endDate, interval: interval)
    }

    private func getStatisticsResult(type: HKQuantityType, unit: HKUnit,
                          startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse> {
        return .create {[weak self] observer in
            guard let self = self else {return Disposables.create()}

            let query = self.getStatisticsQuery(type: type, endDate: endDate, interval: interval)
            query.initialResultsHandler = { _, results, error in
                var valuesResult: [Date: Double] = [:]
                guard let results = results else {
                    print("Error returned form resultHandler = \(String(describing: error?.localizedDescription))")
                    observer(.success(HealthKitResponse(values: nil, hasPermission: false)))
                    return
                }

                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let values = sum.doubleValue(for: unit)
                        valuesResult.updateValue(values, forKey: statistics.startDate)
                        print("Helthkit values:\(valuesResult) , date: \(statistics.startDate)")
                    }
                }
                print(valuesResult)
                // swiftlint:disable line_length
                observer(.success(HealthKitResponse(values: valuesResult, hasPermission: self.healthStore.authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .stepCount)!) == .sharingAuthorized)))
                // swiftlint:enable line_length
            }

            self.healthStore.execute(query)
            return Disposables.create()
        }
    }

    private func getStatisticsQuery(type: HKQuantityType, endDate: Date, interval: DateInterval) -> HKStatisticsCollectionQuery {
        let intervalComponents = interval.value
        // intervalComponents.timeZone = Calendar.current.timeZone
        var anchorComponents = Calendar.current.dateComponents([.day, .month, .year], from: endDate)
        anchorComponents.hour = 0
        let anchorDate = Calendar.current.date(from: anchorComponents)!
        // let anchorDate = Date().startOfDay

        let predicate = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: [.cumulativeSum],
            anchorDate: anchorDate,
            intervalComponents: intervalComponents
        )
        return query
    }

    public func requestAutharization(completion: @escaping (Bool) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let bloodGlucose = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        // Blood Pressure
        let bloodPressureSystolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
        let bloodPressureDiastolic = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let bodyTemperature = HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!
        let oxygenSaturation = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
        let flightsClimbed = HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!
        
        let sleepAnalysis = HKQuantityType.categoryType(forIdentifier: .sleepAnalysis)
        
        
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let energyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let walkingSpeedType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        
        let quantityTypes = Set<HKObjectType>([stepType, bloodGlucose, bloodPressureSystolic, bloodPressureDiastolic, heartRate, bodyTemperature, oxygenSaturation, flightsClimbed, distanceType, energyBurnedType, walkingSpeedType])
        let writableTypes: Set<HKSampleType> = [HKQuantityType.quantityType(forIdentifier: .stepCount)!]
        healthStore.requestAuthorization(toShare: writableTypes, read: quantityTypes,
                                         completion: { sucess, error in
            DispatchQueue.main.async {
                if let err = error as? HKError {
                    print(err.localizedDescription)
                    completion(false)
                    return
                }
                if sucess {
                    if #available(iOS 12.0, *) {
                        switch self.healthStore.authorizationStatus(for: stepType) {
                        case .notDetermined, .sharingDenied:
                            completion(false)
                        case .sharingAuthorized:
                            completion(true)
                        @unknown default:
                            completion(false)
                        }
                        UserDefaults.standard.set(true, forKey: "didCheckPermission")
                    } else {
                        // swiftlint:disable line_length
                        if self.healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!) == .sharingAuthorized {
                            // swiftlint:enable line_length
                            print("Permission Granted to Access BodyMass")
                            completion(true)
                        } else {
                            print("Permission Denied to Access BodyMass")
                            completion(false)
                        }
                        UserDefaults.standard.set(true, forKey: "didCheckPermission")
                    }
                }
            }
        })
    }

    func onPermissionDenied() {
        if let url = URL(string: "x-apple-health://sources/HealthKitManager") {
            if UIApplication.shared.canOpenURL(url) {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
}

struct HealthKitResponse {
    let values: [Date: Double]?
    let hasPermission: Bool

    var total: Double {
        values?.compactMap { $0.value }.reduce(0, +) ?? 0
    }
}

enum DateInterval {
    case hour, day, month
    var value: DateComponents {
        set {}
        get {
            switch self {
            case .hour: return DateComponents(hour: 1)
            case .day: return DateComponents(day: 1)
            case .month: return DateComponents(month: 1)
            }
        }
    }
}
