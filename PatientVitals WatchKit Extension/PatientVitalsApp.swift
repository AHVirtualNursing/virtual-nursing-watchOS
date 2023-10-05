//
//  PatientVitalsApp.swift
//  PatientVitals WatchKit Extension
//
//  Created by Guo Jun on 27/9/23.
//

import SwiftUI

@main
struct PatientVitalsApp: App {
    @StateObject var workoutManager = WorkoutManager()
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                StartView()
            }
            .sheet(isPresented: $workoutManager.showingSummaryView) {
                SummaryView()
            }
            .environmentObject(workoutManager)
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
