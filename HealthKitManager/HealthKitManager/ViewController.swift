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
    
    func getReadings(withType type: String) {
        HealthKitManager.sharedInstance.readDataFromHealthKitWith(type: type, startData: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, endData: Date(), interval: .hour) { result, error in
            if let error { print("error") }
            else {
                print(result)
            }
             
        }
    }
}
