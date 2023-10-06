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
    
    var body: some View {
        VStack {
            Text("Device Serial Number: \(serialNumber)").font(.system(.title3, design: .rounded))
            
            List(workoutTypes) { workoutType in
                NavigationLink(
                    workoutType.name,
                    destination: SessionPagingView(),
                    tag: workoutType,
                    selection: $workoutManager.selectedWorkout
                ).padding(EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5)
                )
            }
            .listStyle(.carousel)
            .navigationBarTitle("Vitals")
            .onAppear {
                workoutManager.requestAuthorisation()
                
                if let simulatorUUID = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] {
                   self.serialNumber = simulatorUUID
               }
            }
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
