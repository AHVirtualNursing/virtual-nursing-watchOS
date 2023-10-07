//
//  ContentView.swift
//  PatientVitals WatchKit Extension
//
//  Created by Guo Jun on 27/9/23.
//

import SwiftUI
import HealthKit

struct StartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    var workoutTypes: [HKWorkoutActivityType] = [.running]
    
    @State private var serialNumber: String = ""
    @State private var patientName: String = ""

    var body: some View {
        ScrollView {
                   VStack {
                       Text("Device Serial Number: \(serialNumber)")
                           .font(.system(.title3, design: .rounded))
                           .frame(width: 200, alignment: .leading)
                       Text("Patient Assigned: \(patientName)")
                           .font(.system(.title3, design: .rounded))
                           .frame(width: 200, alignment: .leading)
                           .onAppear {
                               self.fetchSmartWearableData()
                           }

                       ForEach(workoutTypes, id: \.self) { workoutType in
                           NavigationLink(
                               workoutType.name,
                               destination: SessionPagingView(),
                               tag: workoutType,
                               selection: $workoutManager.selectedWorkout
                           )
                           .padding(EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5))
                       }
                       .listStyle(.carousel)
                   }
                   .navigationBarTitle("Vitals")
                   .onAppear {
                       workoutManager.requestAuthorisation()

                       if let simulatorUUID = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] {
                           self.serialNumber = simulatorUUID
                       }
                   }
               }
    }
        
    private func fetchSmartWearableData() {
        if let url = URL(string: "http://localhost:3001/smartWearable/serialNumber/\(self.serialNumber)") {
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
                                self.fetchPatientName(patientId: patientId)
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
    
    private func fetchPatientName(patientId: String) {
        if let patientURL = URL(string: "http://localhost:3001/patient/\(patientId)") {
            let session = URLSession.shared
            let task = session.dataTask(with: patientURL) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    return
                }

                if let data = data {
                    do {
                        if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            print("Received patient data: \(jsonObject)")
                            if let patientName = jsonObject["name"] as? String {
                                self.patientName = patientName
                            }
                        }
                    } catch {
                        print("Error parsing patient JSON: \(error)")
                    }
                }
            }
            task.resume()
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}

extension HKWorkoutActivityType: Identifiable {
    public var id: UInt {
        rawValue
    }
    
    var name: String {
        switch self {
        case .running:
            return "Start Monitoring"
        default:
            return ""
        }
    }
    
}
