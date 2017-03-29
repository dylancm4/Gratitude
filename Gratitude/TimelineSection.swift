//
//  TimelineSection.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

// Represents a section in a timeline table.
class TimelineSection {
    
    let week: Int
    let year: Int
    let title: String
    var entries = [Entry]()
    
    var rows: Int {
        
        return entries.count
    }
    
    init(week: Int, year: Int) {
        
        self.week = week
        self.year = year
        self.title = String(format: "Week %d, %d", week, year)
    }
    
    // Add the specified entry to the end of the entries array.
    func append(entry: Entry) {
        
        entries.append(entry)
    }
    
    // Add the specified entry to the start of the entries array.
    func prepend(entry: Entry) {
        
        entries.insert(entry, at: 0)
    }
    
    // Return the specified entry from the entries array.
    func get(entryAtRow atRow: Int) -> Entry {
        
        return entries[atRow]
    }
    
    // Remove the specified entry from the entries array.
    func remove(entryAtRow atRow: Int) {
        
        entries.remove(at: atRow)
    }    
    
    // Remove the entry with an ID matching the specified entry, if found.
    // Return true if an entry was removed, false otherwise.
    func remove(entry: Entry) -> Bool {
        
        if let index = getRow(entryWithId: entry.id!) {
            
            remove(entryAtRow: index)
            return true
        }
        else {
            
            return false
        }
    }
    
    // Replace the the specified entry, if found. Return true if an entry was
    // updated, false otherwise.
    func replace(entryWithId entryId: String, replacementEntry: Entry) -> Bool {
        
        if let index = getRow(entryWithId: entryId) {
            
            // entries[index] and replacementEntry may or may not reference the
            // same Entry object, so we copy replacementEntry to entries[index].
            entries[index] = replacementEntry
            
            return true
        }
        else {
            
            return false
        }
    }
    
    // Return the row index of the entry with an ID matching the specified
    // entry, if found. Otherwise, return nil.
    func getRow(entryWithId entryId: String) -> Int? {
        
        for (entryIndex, entry) in entries.enumerated() {
            
            if entry.id == entryId {
                
                return entryIndex
            }
        }
        return nil
    }
}
