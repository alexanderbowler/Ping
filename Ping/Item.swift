//
//  Item.swift
//  Ping
//
//  Created by Alexander Bowler on 2/6/26.
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
