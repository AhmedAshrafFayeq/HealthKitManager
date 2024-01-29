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
    let dispose = DisposeBag()
    
    private init() { }

    func readDataFromHealthKitWith(type: String, startData: Date, endData: Date, interval: DateInterval, completionHandler: @escaping (_ result: [[String: Any]]?, String?) -> Void) {
        
        switch HealthKitType(rawValue: type) {
        case .BloodGlucose:
            healthKitService.requestAutharization { [weak self] isAuthorized in
                if isAuthorized {
                    self?.healthKitService.getBloodGlucose(startDate: startData, endDate: endData) { result, error in
                        completionHandler(result, error)
                    }
                } else {
                    completionHandler(nil, "Unauthorized")
                }
            }
            
        default: break
        }
    }
}

struct BloodGlucoseResponse {
    let values: [Date: Double]?
    let hasPermission: Bool

    var total: Double {
        values?.compactMap { $0.value }.reduce(0, +) ?? 0
    }
}

enum HealthKitType: String {
    case BloodGlucose               = "HKQuantityTypeIdentifierBloodGlucose"
    case Systolic                   = "bloodPressureSystolic"
    case Diastolic                  = "bloodPressureDiastolic"
    case SleepAnalysis              = "HKCategoryTypeIdentifierSleepAnalysis"
    case HeartRate                  = "HKQuantityTypeIdentifierHeartRate"
    case BodyTemperature            = "HKQuantityTypeIdentifierBodyTemperature"
    case OxygenSaturation           = "HKQuantityTypeIdentifierOxygenSaturation"
    case DistanceWalkingRunning     = "HKQuantityTypeIdentifierDistanceWalkingRunning"
    case FlightsClimbed             = "HKQuantityTypeIdentifierFlightsClimbed"
}
