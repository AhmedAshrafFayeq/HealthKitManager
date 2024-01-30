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
    func requestAutharization(completion: @escaping (Bool) -> Void)
    func getBloodGlucoseReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
    func getHeartRateReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
    func getOxygenSaturationReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
    func getBloodPressureDiastolicReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
    
    
    
//    func getStepsCount(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse>
//    func getCalories(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse>
//    func getDistance(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse>
//    func getExerciseTime(startDate: Date, endDate: Date, interval: DateInterval) -> Single<HealthKitResponse>
//    func onPermissionDenied()
}

public final class HealthKitService: HealthKitServiceProtocol {
    let healthStore = HKHealthStore()
    
    func getBloodPressureDiastolicReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void){
        guard let diastolicType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic) else {
            completionHandler(nil, "Blood Pressure data type is not available.")
            return
        }
        readHealthKitData(quantityType: diastolicType, startDate: startDate, endDate: endDate) { [weak self] result, _, error in
            if let error {completionHandler(nil, error)}
            else {
                let readings = self?.getBloodPressureDiastolicFormatedResponse(bloodPressureDiastolicSamples: result ?? [])
                completionHandler(readings, nil)
            }
        }
    }
    

    func getBloodGlucoseReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        guard let bloodGlucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            completionHandler(nil, "Blood Glucose data not available")
            return
        }
        readHealthKitData(quantityType: bloodGlucoseType, startDate: startDate, endDate: endDate) { [weak self] _, result, error in
            if let error {completionHandler(nil, error)}
            else {
                let readings = self?.getBloodGlucoseFormatedResponse(bloodGlucoseSamples: result ?? [])
                completionHandler(readings, nil)
            }
        }
    }
    
    func getHeartRateReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completionHandler(nil, "Heart Rate data not available")
            return
        }
        readHealthKitData(quantityType: heartRateType, startDate: startDate, endDate: endDate) { [weak self] _, result, error in
            if let error {completionHandler(nil, error)}
            else {
                let readings = self?.getHeartRateFormatedResponse(heartRateSamples: result ?? [])
                completionHandler(readings, nil)
            }
        }
    }
    
    func getOxygenSaturationReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        guard let oxygenSaturationType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
            completionHandler(nil, "Oxygen Saturation data not available")
            return
        }
        readHealthKitData(quantityType: oxygenSaturationType, startDate: startDate, endDate: endDate) { [weak self] _, result, error in
            if let error {completionHandler(nil, error)}
            else {
                let readings = self?.getOxygenSaturationFormatedResponse(OxygenSaturationSamples: result ?? [])
                completionHandler(readings, nil)
            }
        }
    }
    func isBloodPressureReques(quantityType: HKQuantityType)-> Bool {
        return quantityType == HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic) || quantityType == HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)
    }

    
    //MARK: -HealthKit Reading Query
    private func readHealthKitData(quantityType: HKQuantityType, startDate: Date, endDate: Date, completion: @escaping (_ result: [HKCorrelation]?, [HKQuantitySample]?, String?) -> Void) {
        //Create the predicate
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let userEnteredPredicate = NSPredicate(format: "metadata.%K != NO", HKMetadataKeyWasUserEntered)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, userEnteredPredicate])
        // Create a sample query
        
        if isBloodPressureReques(quantityType: quantityType){
            guard let type = HKQuantityType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure) else {completion (nil, nil, "Error")
                return
            }
            let query = HKSampleQuery(sampleType: type, predicate: compoundPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
                if let dataList = results as? [HKCorrelation] {
                    completion(dataList, nil, nil)
                } else {
                    completion(nil, nil, "Error reading HealthKit data: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            HKHealthStore().execute(query)
        } else {
            let query = HKSampleQuery(sampleType: quantityType, predicate: compoundPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
                if let samples = results as? [HKQuantitySample] {
                    completion(nil, samples, nil)
                } else {
                    completion(nil, nil, "Error reading HealthKit data: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            // Execute the query
            HKHealthStore().execute(query)
            
        }
    }
    
    //MARK: -HKQuantityTypes Customized Responses
    private func getBloodPressureDiastolicFormatedResponse(bloodPressureDiastolicSamples: [HKCorrelation])-> [[String: Any]]? {
        var data: [[String: Any]] = []
        guard let type = HKQuantityType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure),
               let systolicType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic),
               let diastolicType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic) else {
            return []
           }
        
        for sample in bloodPressureDiastolicSamples {
            let date = sample.startDate
            if let data1 = sample.objects(for: systolicType).first as? HKQuantitySample,
               let data2 = sample.objects(for: diastolicType).first as? HKQuantitySample {
                
                let value1 = data1.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                let value2 = data2.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                
                print("Blood Pressure Diastolic Value: \(value1) \(value2) mmHg, Date: \(date)")
                data.append(["type": "Blood Glucose",
                             "systolic": value1,
                             "diastolic": value2,
                             "unit": "mg/dL",
                             "timestamp": date])
            }
            
            
        }
        return data
    }
    private func getBloodGlucoseFormatedResponse(bloodGlucoseSamples: [HKQuantitySample])-> [[String: Any]]? {
        var data: [[String: Any]] = []
        for sample in bloodGlucoseSamples {
            let value = sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
            let date = sample.startDate
            print("Blood Glucose Value: \(value) mg/dL, Date: \(date)")
            data.append(["type": "Blood Glucose",
                         "value": value,
                         "unit": "mg/dL",
                         "timestamp": date])
        }
        return data
    }
    private func getHeartRateFormatedResponse(heartRateSamples: [HKQuantitySample])-> [[String: Any]]? {
        var data: [[String: Any]] = []
        for sample in heartRateSamples {
            let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            let date = sample.startDate
            print("Heart Rate Value: \(value) BPM, Date: \(date)")
            data.append(["type": "Heart Rate",
                    "value": value,
                    "unit": "BPM",
                    "timestamp": date])
        }
        return data
    }
    private func getOxygenSaturationFormatedResponse(OxygenSaturationSamples: [HKQuantitySample])-> [[String: Any]]? {
        var data: [[String: Any]] = []
        for sample in OxygenSaturationSamples {
            let value = sample.quantity.doubleValue(for: HKUnit(from: "%")) * 100
            let date = sample.startDate
            print("Oxygen Saturation Value: \(value) %, Date: \(date)")
            data.append(["type": "Oxygen Saturation",
                    "value": value,
                    "unit": "%",
                    "timestamp": date])
        }
        return data
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
