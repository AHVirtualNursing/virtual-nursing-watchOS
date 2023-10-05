//
//  MetricsView.swift
//  PatientVitals WatchKit Extension
//
//  Created by Guo Jun on 27/9/23.
//

import SwiftUI

struct MetricsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        TimelineView(
            MetricsTimelineSchedule(
                from: workoutManager.builder?.startDate ?? Date()
            )
        ) { context in
            ScrollView {
                VStack(alignment: .leading) {
                    ElapsedTimeView(
                        elapsedTime: workoutManager.builder?.elapsedTime ?? 0,
                        showSubseconds: context.cadence == .live
                    ).foregroundColor(Color.yellow)
                    Text(
                        workoutManager.heartRate
                            .formatted(
                                .number.precision(.fractionLength(0))
                            )
                        + " bpm"
                    )
                    Text(
                        workoutManager.respiratoryRate
                            .formatted(
                                .number.precision(.fractionLength(0))
                            )
                        + " br/m"
                    )
                    Text(
                        workoutManager.oxygenSaturation
                            .formatted(
                                .number.precision(.fractionLength(0))
                            )
                        + " %"
                    )
                    Text(
                        workoutManager.bloodPressureDiastolic
                            .formatted(
                                .number.precision(.fractionLength(0))
                            )
                        + " mm Hg"
                    )
                    Text(
                        workoutManager.bloodPressureSystolic
                            .formatted(
                                .number.precision(.fractionLength(0))
                            )
                        + " mm Hg"
                    )
                }
                .font(.system(.title, design: .rounded)
                            .monospacedDigit()
                            .lowercaseSmallCaps()
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ignoresSafeArea(edges: .bottom)
                    .scenePadding()
            }
        }
    }
}

struct MetricsView_Previews: PreviewProvider {
    static var previews: some View {
        MetricsView()
    }
}

private struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date

    init(from startDate: Date) {
        self.startDate = startDate
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> PeriodicTimelineSchedule.Entries {
        PeriodicTimelineSchedule(
            from: self.startDate,
            by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0)
        ).entries(
            from: startDate,
            mode: mode
        )
    }
}
