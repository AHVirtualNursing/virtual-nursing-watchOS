//
//  SummaryMetricView.swift
//  PatientVitals WatchKit Extension
//
//  Created by Guo Jun on 27/9/23.
//

import SwiftUI
import HealthKit

struct SummaryView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    var body: some View {
        if workoutManager.workout == nil {
            ProgressView("Saving vitals")
                .navigationBarHidden(true)
        } else {
            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    SummaryMetricView(
                        title: "Total Time",
                        value: durationFormatter
                            .string(from: workoutManager.workout?.duration ?? 0.0) ?? ""
                    ).accentColor(Color.yellow)
                    SummaryMetricView(
                        title: "Avg. Heart Rate",
                        value: workoutManager.averageHeartRate
                            .formatted(
                                .number.precision(.fractionLength(0))
                            )
                        + " bpm"
                    ).accentColor(Color.red)
                    Button("Done") {
                        dismiss()
                    }
                }
                .scenePadding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView()
    }
}

struct SummaryMetricView: View {
    var title: String
    var value: String

    var body: some View {
        Text(title)
        Text(value)
            .font(.system(.title2, design: .rounded)
                    .lowercaseSmallCaps()
            )
            .foregroundColor(.accentColor)
        Divider()
    }
}
