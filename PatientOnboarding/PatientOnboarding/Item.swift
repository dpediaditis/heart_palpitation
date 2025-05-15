//
//  Item.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
