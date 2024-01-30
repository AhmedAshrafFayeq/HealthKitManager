//
//  HealthKitManager.swift
//  HealthKitManager
//
//  Created by Ahmed Fayek on 28/01/2024.
//

import Foundation
import RxSwift
import HealthKit

class HealthKitManager {
    static let sharedInstance = HealthKitManager()
    var healthKitService = HealthKitService()
    
    private init() { }

    func readDataFromHealthKitWith(type: String, startData: Date, endData: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        healthKitService.requestAutharization { [weak self] isAuthorized in
            guard let self else {return}
            if isAuthorized {
                switch HealthKitType(rawValue: type) {
                    
                case .BloodGlucose:
                    self.healthKitService.getBloodGlucoseReadings(startDate: startData, endDate: endData) { result, error in
                        completionHandler(result, error)
                    }
                    
                case .HeartRate:
                    self.healthKitService.getHeartRateReadings(startDate: startData, endDate: endData) { result, error in
                        completionHandler(result, error)
                    }
                    
                case .OxygenSaturation:
                    self.healthKitService.getOxygenSaturationReadings(startDate: startData, endDate: endData) { result, error in
                        completionHandler(result, error)
                    }
                    
                case .BloodPressure, .Systolic, .Diastolic:
                    self.healthKitService.getBloodPressureDiastolicReadings(startDate: startData, endDate: endData) { result, error in
                        completionHandler(result, error)
                    }
                    
                case .StepsCount:
                    self.healthKitService.getStepsCount(startDate: startData, endDate: endData, interval: interval) { result, error in
                        completionHandler(result, error)
                    }
                    
                case .FlightsClimbed:
                    self.healthKitService.getFlightsClimbedCount(startDate: startData, endDate: endData, interval: interval) { result, error in
                        completionHandler(result, error)
                    }
                    
                case .BodyTemperature:
                    self.healthKitService.getBodyTemperature(startDate: startData, endDate: endData, interval: interval) { result, error in
                        completionHandler(result, error)
                    }
                default: break
                }

            } else {
                completionHandler(nil, "Unauthorized")
            }
        }
    }
}

enum HealthKitType: String {
    case BloodGlucose               = "HKQuantityTypeIdentifierBloodGlucose"
    case BloodPressure              = "BloodPressure"
    case Systolic                   = "bloodPressureSystolic"
    case Diastolic                  = "bloodPressureDiastolic"
    case SleepAnalysis              = "HKCategoryTypeIdentifierSleepAnalysis"
    case HeartRate                  = "HKQuantityTypeIdentifierHeartRate"
    case BodyTemperature            = "HKQuantityTypeIdentifierBodyTemperature"
    case OxygenSaturation           = "HKQuantityTypeIdentifierOxygenSaturation"
    case DistanceWalkingRunning     = "HKQuantityTypeIdentifierDistanceWalkingRunning"
    case FlightsClimbed             = "HKQuantityTypeIdentifierFlightsClimbed"
    case StepsCount                 = "HKQuantityTypeIdentifierStepCount"
}
