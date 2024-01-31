//
//  ViewController.swift
//  HealthKitManager
//
//  Created by Ahmed Fayek on 28/01/2024.
//

import UIKit
import RxSwift

class ViewController: UIViewController {
    var healthKitService = HealthKitService()
    public let dispose = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func didTapHeartRate(_ sender: Any) {
        getReadings(withType: "HKQuantityTypeIdentifierHeartRate")
    }
    @IBAction func didTapBloodGlucose(_ sender: Any) {
        getReadings(withType: "HKQuantityTypeIdentifierBloodGlucose")
    }
    
    @IBAction func didTapOxygenSaturation(_ sender: Any) {
        getReadings(withType: "HKQuantityTypeIdentifierOxygenSaturation")
    }
    @IBAction func didTapBloodPressure(_ sender: Any) {
//        getReadings(withType: "bloodPressureSystolic")
        getReadings(withType: "bloodPressureDiastolic")
    }
    
    @IBAction func didTapStepsCount(_ sender: Any) {
        getReadings(withType: "HKQuantityTypeIdentifierStepCount")
    }
    
    @IBAction func didTapStairsClimbed(_ sender: Any) {
        getReadings(withType: "HKQuantityTypeIdentifierFlightsClimbed")
    }
    
    @IBAction func didTapBodyTemprature(_ sender: Any) {
        getReadings(withType: "HKQuantityTypeIdentifierBodyTemperature")
    }
    
    @IBAction func didTapActiveEnergyBurned(_ sender: Any) {
        getReadings(withType: "HKQuantityTypeIdentifierActiveEnergyBurned")
    }
    
    @IBAction func didTapDistance(_ sender: Any) {
        getReadings(withType: "HKQuantityTypeIdentifierDistanceWalkingRunning")
    }
    
    @IBAction func didTapSleepAnalysis(_ sender: Any) {
        getReadings(withType: "HKCategoryTypeIdentifierSleepAnalysis")
    }
    
    func getReadings(withType type: String) {
        HealthKitManager.sharedInstance.readDataFromHealthKitWith(type: type, startData: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, endData: Date(), interval: .hour) { result, error in
            if let error { print(error) }
            if let result {
                print(result)
            }
        }
    }
}
