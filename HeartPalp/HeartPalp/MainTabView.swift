//
//  MainTabView.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 19/4/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
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
