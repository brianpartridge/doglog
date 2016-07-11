//
//  Event.swift
//  Dog Log
//
//  Created by Brian Partridge on 7/9/16.
//  Copyright © 2016 Pear Tree Labs. All rights reserved.
//

import CoreData
import Foundation

public enum Type: Int32, CustomStringConvertible {
    case WalkBegin
    case WalkEnd
    case Meal
    case Snack
    case Pee
    case Poop
    
    static public var allValues: [Type] {
        return [.WalkBegin, .WalkEnd, .Meal, .Snack, .Pee, .Poop]
    }
    
    public var description: String {
        switch self {
        case .WalkBegin: return "Walk Began"
        case .WalkEnd: return "Walk Ended"
        case .Meal: return "Meal"
        case .Snack: return "Snack"
        case .Pee: return "Pee"
        case .Poop: return "Poop"
        }
    }
    
    public var emojiDescription: String {
        switch self {
        case .WalkBegin: return "🏃🏼"
        case .WalkEnd: return "🚶🏼"
        case .Meal: return "🍔"
        case .Snack: return "🍌"
        case .Pee: return "🚽"
        case .Poop: return "💩"
        }
    }
}

public class Event: NSManagedObject {
    
    /// Force unwrapped because this property didn't exist in v1 of the model and we need to populate it if empty.
    @NSManaged var dayStamp: NSDate!
    @NSManaged var note: String
    @NSManaged var timeStamp: NSDate
    
    @NSManaged var type: Int32
    
    var enumType: Type {
        get {
            return Type(rawValue: type)!
        }
        set {
            type = newValue.rawValue
        }
    }
    
    func updateTimeStamp(date: NSDate) {
        timeStamp = date
        dayStamp = NSCalendar.currentCalendar().components([.Calendar, .Era, .Year, .Month, .Day], fromDate: date).date!
    }
    
    // MARK: - NSManagedObject
    
    override public func awakeFromFetch() {
        super.awakeFromFetch()
        
        if let _ = dayStamp { } else {
            updateTimeStamp(timeStamp)
        }
    }
}
