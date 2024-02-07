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
    
    @IBOutlet weak var stepsCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        healthKitService.startObservingHealthDataChanges { [weak self] in
            guard let self else { return }            
            HealthKitManager.sharedInstance.readDataFromHealthKitWith(type: .StepsCount, startData: Date(), endData: Date(), interval: .day) { result, error in
                if let error { print(error) }
                if let result {
                    print(result)
                    if let count = result.first?["count"] {
                        DispatchQueue.main.async {
                            self.stepsCountLabel.text = "\(count)"
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func didTapHeartRate(_ sender: Any) {
        getReadings(withType: .HeartRate)
    }
    @IBAction func didTapBloodGlucose(_ sender: Any) {
        getReadings(withType: .BloodGlucose)
    }
    
    @IBAction func didTapOxygenSaturation(_ sender: Any) {
        getReadings(withType: .OxygenSaturation)
    }
    @IBAction func didTapBloodPressure(_ sender: Any) {
//        getReadings(withType: "bloodPressureSystolic")
        getReadings(withType: .Diastolic)
    }
    
    @IBAction func didTapStepsCount(_ sender: Any) {
        getReadings(withType: .StepsCount)
    }
    
    @IBAction func didTapStairsClimbed(_ sender: Any) {
        getReadings(withType: .FlightsClimbed)
    }
    
    @IBAction func didTapBodyTemprature(_ sender: Any) {
        getReadings(withType: .BodyTemperature)
    }
    
    @IBAction func didTapActiveEnergyBurned(_ sender: Any) {
        getReadings(withType: .ActiveEnergyBurned)
    }
    
    @IBAction func didTapDistance(_ sender: Any) {
        getReadings(withType: .DistanceWalkingRunning)
    }
    
    @IBAction func didTapSleepAnalysis(_ sender: Any) {
        getReadings(withType: .SleepAnalysis)
    }
    
    func getReadings(withType type: HealthKitType) {
        HealthKitManager.sharedInstance.readDataFromHealthKitWith(type: type, startData: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, endData: Date(), interval: .hour) { result, error in
            if let error { print(error) }
            if let result {
                print(result)
            }
        }
    }
}
