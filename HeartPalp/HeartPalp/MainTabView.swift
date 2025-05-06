//
//  MainTabView.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 19/4/25.
//

import SwiftUI
import SpeziQuestionnaire


struct MainTabView: View {
    var body: some View {
        TabView {
//            QuestionnaireView()
//                            .tabItem {
//                                Label("Check-In", systemImage: "stethoscope")
//                            }
            
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "heart.fill")
                }

            CalendarLogView()
                .tabItem {
                    Label("Logs", systemImage: "calendar")
                }
        }
    }
}
