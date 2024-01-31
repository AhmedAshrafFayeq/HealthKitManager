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
    func getSleepAnalysis(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
    func getBloodPressureDiastolicReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
    func getStepsCount(startDate: Date, endDate: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
    func getFlightsClimbedCount(startDate: Date, endDate: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
    func getBodyTemperature(startDate: Date, endDate: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
    func getActiveEnergyBurned(startDate: Date, endDate: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
    func getDistance(startDate: Date, endDate: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void)
}

public final class HealthKitService: HealthKitServiceProtocol {
    let healthStore = HKHealthStore()
    
    //MARK: -Blood Pressure Systolic
    func getBloodPressureSystolicReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void){
        guard let diastolicType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic) else {
            completionHandler(nil, "Blood Pressure data type is not available.")
            return
        }
        readHealthKitData(objectType: diastolicType, startDate: startDate, endDate: endDate) { [weak self] result, _, error in
            if let error {completionHandler(nil, error)}
            else {
                let readings = self?.getBloodPressureFormatedResponse(bloodPressureSamples: result ?? [])
                completionHandler(readings, nil)
            }
        }
    }
    //MARK: -Blood Pressure Diastolic
    func getBloodPressureDiastolicReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void){
        guard let diastolicType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic) else {
            completionHandler(nil, "Blood Pressure data type is not available.")
            return
        }
        readHealthKitData(objectType: diastolicType, startDate: startDate, endDate: endDate) { [weak self] result, _, error in
            if let error {completionHandler(nil, error)}
            else {
                let readings = self?.getBloodPressureFormatedResponse(bloodPressureSamples: result ?? [])
                completionHandler(readings, nil)
            }
        }
    }
    //MARK: -Blood Glucose
    func getBloodGlucoseReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        guard let bloodGlucoseType = HKObjectType.quantityType(forIdentifier: .bloodGlucose) else {
            completionHandler(nil, "Blood Glucose data not available")
            return
        }
        readHealthKitData(objectType: bloodGlucoseType, startDate: startDate, endDate: endDate) { [weak self] _, result, error in
            if let error {completionHandler(nil, error)}
            else {
                let readings = self?.getBloodGlucoseFormatedResponse(bloodGlucoseSamples: result ?? [])
                completionHandler(readings, nil)
            }
        }
    }
    //MARK: -Heart Rate
    func getHeartRateReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completionHandler(nil, "Heart Rate data not available")
            return
        }
        readHealthKitData(objectType: heartRateType, startDate: startDate, endDate: endDate) { [weak self] _, result, error in
            if let error {completionHandler(nil, error)}
            else {
                let readings = self?.getHeartRateFormatedResponse(heartRateSamples: result ?? [])
                completionHandler(readings, nil)
            }
        }
    }
    //MARK: -Oxygen Saturation
    func getOxygenSaturationReadings(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        guard let oxygenSaturationType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
            completionHandler(nil, "Oxygen Saturation data not available")
            return
        }
        readHealthKitData(objectType: oxygenSaturationType, startDate: startDate, endDate: endDate) { [weak self] _, result, error in
            if let error {completionHandler(nil, error)}
            else {
                let readings = self?.getOxygenSaturationFormatedResponse(oxygenSaturationSamples: result ?? [])
                completionHandler(readings, nil)
            }
        }
    }
    //MARK: -Sleep Analysis
    func getSleepAnalysis(startDate: Date, endDate: Date, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        guard let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completionHandler(nil, "Sleep Analysis data not available")
            return
        }
        readHealthKitData(objectType: sleepAnalysisType, startDate: startDate, endDate: endDate) { [weak self] _, result, error in
            if let error {completionHandler(nil, error)}
            else {
                let readings = self?.getSleepAnalysisFormatedResponse(sleepAnalysisSamples: result ?? [])
                completionHandler(readings, nil)
            }
        }
    }
    
    //MARK: -Steps Count
    func getStepsCount(startDate: Date, endDate: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        getStatisticsResult(type: .stepCount, startDate: startDate, endDate: endDate, interval: interval) { [weak self] result, error in
            if let error {completionHandler(nil, error)}
            if let result {
                let readings = self?.getStepsCountFormatedResponse(statistics: result)
                completionHandler(readings, nil)
            }
        }
    }
    //MARK: -Steps Count
    func getFlightsClimbedCount(startDate: Date, endDate: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        getStatisticsResult(type: .flightsClimbed, startDate: startDate, endDate: endDate, interval: interval) { [weak self] result, error in
            if let error {completionHandler(nil, error)}
            if let result {
                let readings = self?.getFlightsClimbedResponse(statistics: result)
                completionHandler(readings, nil)
            }
        }
    }
    //MARK: -Body Temperature
    func getBodyTemperature(startDate: Date, endDate: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        getStatisticsResult(type: .bodyTemperature, startDate: startDate, endDate: endDate, interval: interval) { [weak self] result, error in
            if let error {completionHandler(nil, error)}
            if let result {
                let readings = self?.getBodyTemperatureResponse(statistics: result)
                completionHandler(readings, nil)
            }
        }
    }
    //MARK: -Calories
    func getActiveEnergyBurned(startDate: Date, endDate: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        getStatisticsResult(type: .activeEnergyBurned, startDate: startDate, endDate: endDate, interval: interval) { [weak self] result, error in
            if let error {completionHandler(nil, error)}
            if let result {
                let readings = self?.getActiveEnergyBurnedResponse(statistics: result)
                completionHandler(readings, nil)
            }
        }
    }
    //MARK: -Distance
    func getDistance(startDate: Date, endDate: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        getStatisticsResult(type: .distanceWalkingRunning, startDate: startDate, endDate: endDate, interval: interval) { [weak self] result, error in
            if let error {completionHandler(nil, error)}
            if let result {
                let readings = self?.getDistanceResponse(statistics: result)
                completionHandler(readings, nil)
            }
        }
    }
    
    func isBloodPressureReques(objectType: HKObjectType)-> Bool {
        return objectType == HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic) || objectType == HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic)
    }

    
    //MARK: -HealthKit Reading Query using HKSampleQuery
    private func readHealthKitData(objectType: HKObjectType, startDate: Date, endDate: Date, completion: @escaping (_ result: [HKCorrelation]?, [HKSample]?, String?) -> Void) {
        
        //Create the predicate
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let userEnteredPredicate = NSPredicate(format: "metadata.%K != NO", HKMetadataKeyWasUserEntered)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, userEnteredPredicate])
        
        // Create a sample query
        if isBloodPressureReques(objectType: objectType){
            guard let type = HKQuantityType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure) else { completion (nil, nil, "Error"); return }
            let query = HKSampleQuery(sampleType: type, predicate: compoundPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
                if let error {
                    completion (nil, nil, "Error querying blood Pressure data: \(error.localizedDescription)")
                }
                if let dataList = results as? [HKCorrelation] {
                    completion(dataList, nil, nil)
                } else {
                    completion(nil, nil, "Error reading blood Pressure data: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            HKHealthStore().execute(query)
            
        } else if objectType == HKObjectType.categoryType(forIdentifier: .sleepAnalysis), let sampleType = objectType as? HKSampleType {
            let query = HKSampleQuery(sampleType: sampleType, predicate: compoundPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                if let error = error {
                    completion (nil, nil, "Error querying sleep analysis data: \(error.localizedDescription)")
                }
                if let sleepSamples = samples as? [HKCategorySample] {
                    completion(nil, sleepSamples, nil)
                }else {
                    completion(nil, nil, "Error reading sleep analysis data: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            HKHealthStore().execute(query)
        }
        else {
            guard let quantityType = objectType as? HKQuantityType else { completion (nil, nil, "Error"); return }
            
            let query = HKSampleQuery(sampleType: quantityType, predicate: compoundPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
                if let error {
                    completion (nil, nil, "Error querying type data: \(error.localizedDescription)")
                }
                if let samples = results as? [HKQuantitySample] {
                    completion(nil, samples, nil)
                } else {
                    completion(nil, nil, "Error reading HealthKit data: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            HKHealthStore().execute(query)
        }
    }
    
    //MARK: -HealthKit Reading Query using HKStatisticsCollectionQuery
    private func getStatisticsResult(type: HKQuantityTypeIdentifier, startDate: Date, endDate: Date, interval: DateInterval, completion: @escaping (_ result: [Date: HKStatistics]?, String?) -> Void) {
        let options = getQueryOptions(type: type)
        guard let query = self.getStatisticsQuery(typeIdentifier: type, options: options, endDate: endDate, interval: interval) else {
            completion(nil, "Invalid Query")
            return
        }
        query.initialResultsHandler = { _, results, error in
            guard let results else {
                completion(nil, "Error returned form resultHandler = \(String(describing: error?.localizedDescription))")
                return
            }
            var statistics: [Date : HKStatistics] = [:]
            results.enumerateStatistics(from: startDate, to: endDate) { singleStatistics, _ in
                statistics.updateValue(singleStatistics, forKey: singleStatistics.startDate)
            }
            completion(statistics, nil)
        }
        self.healthStore.execute(query)
    }
    
    private func getStatisticsQuery(typeIdentifier: HKQuantityTypeIdentifier, options: HKStatisticsOptions, endDate: Date, interval: DateInterval) -> HKStatisticsCollectionQuery? {
        let intervalComponents = interval.value
        var anchorComponents = Calendar.current.dateComponents([.day, .month, .year], from: endDate)
        anchorComponents.hour = 0
        guard let anchorDate = Calendar.current.date(from: anchorComponents) else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: typeIdentifier) else { return nil }
        
        let predicate = NSPredicate(format: "metadata.%K != NO", HKMetadataKeyWasUserEntered)
        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: options,
            anchorDate: anchorDate,
            intervalComponents: intervalComponents
        )
        return query
    }
    
    private func getQueryOptions(type: HKQuantityTypeIdentifier)-> HKStatisticsOptions {
        switch type {
        case .bodyTemperature:
            return [.discreteAverage]
        default:
            return [.cumulativeSum]
        }
    }

    
    //MARK: -HKQuantityTypes Customized Responses
    private func getBloodPressureFormatedResponse(bloodPressureSamples: [HKCorrelation])-> [[String: Any]] {
        var data: [[String: Any]] = []
        guard let _ = HKQuantityType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.bloodPressure),
               let systolicType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureSystolic),
               let diastolicType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bloodPressureDiastolic) else {
            return []
           }
        for sample in bloodPressureSamples {
            if let data1 = sample.objects(for: systolicType).first as? HKQuantitySample,
               let data2 = sample.objects(for: diastolicType).first as? HKQuantitySample {
                let value1 = data1.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                let value2 = data2.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
                data.append(["type": "Blood Glucose",
                             "systolic": value1,
                             "diastolic": value2,
                             "unit": "mg/dL",
                             "timestamp": sample.startDate])
            }
        }
        return data
    }
    
    private func getBloodGlucoseFormatedResponse(bloodGlucoseSamples: [HKSample])-> [[String: Any]] {
        var data: [[String: Any]] = []
        guard let samples = bloodGlucoseSamples as? [HKQuantitySample] else { return data }
        for sample in samples {
            let value = sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
            data.append(["type": "Blood Glucose",
                         "value": value,
                         "unit": "mg/dL",
                         "timestamp": sample.startDate])
        }
        return data
    }
    private func getHeartRateFormatedResponse(heartRateSamples: [HKSample])-> [[String: Any]] {
        var data: [[String: Any]] = []
        guard let samples = heartRateSamples as? [HKQuantitySample] else { return data }
        for sample in samples {
            let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            data.append(["type": "Heart Rate",
                         "value": value,
                         "unit": "BPM",
                         "timestamp": sample.startDate])
        }
        return data
    }
    private func getOxygenSaturationFormatedResponse(oxygenSaturationSamples: [HKSample])-> [[String: Any]] {
        var data: [[String: Any]] = []
        guard let samples = oxygenSaturationSamples as? [HKQuantitySample] else { return data }
        for sample in samples {
            let value = sample.quantity.doubleValue(for: HKUnit(from: "%")) * 100
            data.append(["type": "Oxygen Saturation",
                         "value": value,
                         "unit": "%",
                         "timestamp": sample.startDate])
        }
        return data
    }
    private func getSleepAnalysisFormatedResponse(sleepAnalysisSamples: [HKSample])-> [[String: Any]] {
        var data: [[String: Any]] = []
        guard let samples = sleepAnalysisSamples as? [HKCategorySample] else { return data }
        for sample in samples {
            data.append(["type": "Sleep Analysis",
                         "sleepStage": "Deep Sleep",
                         "durationMinutes": sample.value,
                         "timestamp": sample.startDate])
        }
        return data
    }
    
    private func getStepsCountFormatedResponse(statistics: [Date: HKStatistics]?)-> [[String: Any]] {
        var data: [[String: Any]] = []
        if let statistics {
            for (_ , singleStatistics) in statistics {
                if let value = singleStatistics.sumQuantity()?.doubleValue(for: .count()) {
                    data.append(["type": "Steps",
                                 "count": value,
                                 "timestamp": singleStatistics.startDate])
                }
            }
        }
        return data
    }
    
    private func getFlightsClimbedResponse(statistics: [Date: HKStatistics]?)-> [[String: Any]] {
        var data: [[String: Any]] = []
        if let statistics {
            for (_ , singleStatistics) in statistics {
                if let value = singleStatistics.sumQuantity()?.doubleValue(for: .count()) {
                    data.append(["type": "Stairs Climbed",
                                 "count": value,
                                 "timestamp": singleStatistics.startDate])
                }
            }
        }
        return data
    }
    
    private func getBodyTemperatureResponse(statistics: [Date: HKStatistics]?)-> [[String: Any]] {
        var data: [[String: Any]] = []
        if let statistics {
            for (_ , singleStatistics) in statistics {
                if let value = singleStatistics.averageQuantity()?.doubleValue(for: .degreeCelsius()) {
                    data.append(["type": "Body Temperature",
                                 "count": value,
                                 "unit": "°C",
                                 "timestamp": singleStatistics.startDate])
                }
            }
        }
        return data
    }
    private func getActiveEnergyBurnedResponse(statistics: [Date: HKStatistics]?)-> [[String: Any]] {
        var data: [[String: Any]] = []
        if let statistics {
            for (_ , singleStatistics) in statistics {
                if let value = singleStatistics.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                    data.append(["type": "Burned Calories",
                                 "calories": value,
                                 "unit": "kcal",
                                 "timestamp": singleStatistics.startDate])
                }
            }
        }
        return data
    }
    private func getDistanceResponse(statistics: [Date: HKStatistics]?)-> [[String: Any]] {
        var data: [[String: Any]] = []
        if let statistics {
            for (_ , singleStatistics) in statistics {
                if let value = singleStatistics.sumQuantity()?.doubleValue(for: .meter()) {
                    data.append(["type": "Distance",
                                 "value": value,
                                 "unit": "m",
                                 "timestamp": singleStatistics.startDate])
                }
            }
        }
        return data
    }


    public func requestAutharization(completion: @escaping (Bool) -> Void) {
        let healthKitTypesToRead: Set<HKObjectType> = [
                HKObjectType.quantityType(forIdentifier: .stepCount)!,
                HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
                HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
                HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
                HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
                HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
                HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
                HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
            ]
        let writableTypes: Set<HKSampleType> = [HKQuantityType.quantityType(forIdentifier: .stepCount)!]
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { completion(false); return }
        guard HKHealthStore.isHealthDataAvailable() else { completion(false); return }
        
        healthStore.requestAuthorization(toShare: writableTypes, read: healthKitTypesToRead, completion: { [weak self] sucess, error in
            guard let self else {completion(false); return}
            DispatchQueue.main.async {
                if let _ = error as? HKError    {completion(false); return}
                if sucess {
                    if #available(iOS 12.0, *) {
                        switch self.healthStore.authorizationStatus(for: stepType) {
                        case .notDetermined, .sharingDenied:    completion(false)
                        case .sharingAuthorized:    completion(true)
                        @unknown default:   completion(false)
                        }
                    } else {
                        if self.healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!) == .sharingAuthorized {
                            completion(true)
                        } else {
                            completion(false)
                        }
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
