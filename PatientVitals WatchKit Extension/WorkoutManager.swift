//
//  WorkoutManager.swift
//  PatientVitals WatchKit Extension
//
//  Created by Guo Jun on 27/9/23.
//

import Foundation
import HealthKit
import SocketIO

class WorkoutManager: NSObject, ObservableObject {
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var serialNumber: String?
    private var patientId: String?
    
    private func setUpSocketConnection() {
        let socketURL = URL(string: "http://localhost:3001")!
        manager = SocketManager(socketURL: socketURL, config: [.log(true), .compress])

        socket = manager?.defaultSocket

        socket?.on(clientEvent: .connect) { data, ack in
            print("Socket connected")
            if let simulatorUUID = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] {
                self.serialNumber = simulatorUUID
                self.fetchSmartWearableData()
                self.socket?.emit("connectSmartWatch", self.patientId ?? "")
            }
        }

        socket?.connect()
    }
    
    private func fetchSmartWearableData() {
        if let url = URL(string: "http://localhost:3001/smartWearable/serialNumber/\(self.serialNumber ?? "")") {
            let session = URLSession.shared
            let task = session.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                
                if let data = data {
                    do {
                        if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            print("Received data: \(jsonObject)")
                            if let patientId = jsonObject["patient"] as? String {
                                self.patientId = patientId
                            }
                        }
                    } catch {
                        print("Error parsing JSON: \(error)")
                    }
                }
            }
            task.resume()
        }
    }
    
    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let selectedWorkout = selectedWorkout else { return }
            startWorkout(workoutType: selectedWorkout)
        }
    }
    
    @Published var showingSummaryView: Bool = false {
        didSet {
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    func startWorkout(workoutType: HKWorkoutActivityType) {
        setUpSocketConnection()

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            return
        }
        
        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        
        session?.delegate = self
        builder?.delegate = self
        
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
        }
    }
    
    func handleDataSocketIO() {
        let currentDate = Date()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let formattedDate = dateFormatter.string(from: currentDate)

        let oxygenSaturationType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        let query = HKSampleQuery(
            sampleType: oxygenSaturationType,
            predicate: nil,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil) { (query, results, error) in
            
            if let results = results as? [HKQuantitySample] {
                for result in results {
                    let oxygenSaturationValue = result.quantity.doubleValue(for: HKUnit.percent())
                    print("Oxygen Saturation Value: \(oxygenSaturationValue) %")
                }
            } else {
                print("NO oxygen saturation value")
            }
        }
        healthStore.execute(query)

        
        self.socket?.emit("watchData", ["patientId": self.patientId ?? "", "datetime": formattedDate, "heartRate": heartRate])
    }
    
    func requestAuthorisation() {
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) {
            (success, error) in
        }
    }
    
    // MARK: - State Control

    // The workout session state.
    @Published var running = false

    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }

    func togglePause() {
        if running == true {
            pause()
        } else {
            resume()
        }
    }

    func endWorkout() {
        session?.end()
        self.socket?.disconnect()
        showingSummaryView = true
    }
    
    // MARK: - Workout Metrics
    @Published var averageHeartRate: Double = 0
    @Published var heartRate: Double = 0
    @Published var respiratoryRate: Double = 0
    @Published var oxygenSaturation: Double = 0
    @Published var bloodPressureDiastolic: Double = 0
    @Published var bloodPressureSystolic: Double = 0
    @Published var workout: HKWorkout?

    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }

        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .respiratoryRate):
                let respiratoryRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.respiratoryRate = statistics.mostRecentQuantity()?.doubleValue(for: respiratoryRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .oxygenSaturation):
                let oxygenSaturationUnit = HKUnit.percent()
                self.oxygenSaturation = statistics.mostRecentQuantity()?.doubleValue(for: oxygenSaturationUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic):
                let bloodPressureDiastolicUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.bloodPressureDiastolic = statistics.mostRecentQuantity()?.doubleValue(for: bloodPressureDiastolicUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic):
                let bloodPressureDiastolicUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.bloodPressureSystolic = statistics.mostRecentQuantity()?.doubleValue(for: bloodPressureDiastolicUnit) ?? 0
            default:
                return
            }
        }
    }
    
    func resetWorkout() {
        selectedWorkout = nil
        builder = nil
        session = nil
        workout = nil
        averageHeartRate = 0
        heartRate = 0
        respiratoryRate = 0
        oxygenSaturation = 0
        bloodPressureDiastolic = 0
        bloodPressureSystolic = 0
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }

        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { return }

            let statistics = workoutBuilder.statistics(for: quantityType)

            // Update the published values.
            updateForStatistics(statistics)
            handleDataSocketIO()
        }
    }
}
