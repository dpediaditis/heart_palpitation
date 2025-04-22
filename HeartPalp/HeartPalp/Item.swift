//
//  Item.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 19/4/25.
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
