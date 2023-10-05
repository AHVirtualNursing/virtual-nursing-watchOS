//
//  SessionPagingView.swift
//  PatientVitals WatchKit Extension
//
//  Created by Guo Jun on 27/9/23.
//

import SwiftUI

struct SessionPagingView: View {
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var selection: Tab = .metrics
    
    enum Tab {
        case controls, metrics
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ControlsView().tag(Tab.controls)
            MetricsView().tag(Tab.metrics)
        }
        .navigationTitle(workoutManager.selectedWorkout?.name ?? "")
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(selection == .metrics)
        .tabViewStyle(
            PageTabViewStyle(indexDisplayMode: isLuminanceReduced ? .never : .automatic)
        )
        .onChange(of: isLuminanceReduced) { _ in
            displayMetricsView()
        }
    }
        
    private func displayMetricsView() {
        withAnimation {
            selection = .metrics
        }
    }
}

struct SessionPagingView_Previews: PreviewProvider {
    static var previews: some View {
        SessionPagingView()
    }
}
