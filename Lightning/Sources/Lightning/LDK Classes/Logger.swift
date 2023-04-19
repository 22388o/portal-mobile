//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import LightningDevKit

class Logger: LightningDevKit.Logger {
    override func log(record: Bindings.Record) {
        let messageLevel = record.getLevel()
        let arguments = record.getArgs()
                
        switch messageLevel {
        case .Debug:
            print("LDK LOG - Debug:")
            print("\(arguments)\n")
        case .Info:
            print("LDK LOG - Info:")
            print("\(arguments)\n")
        case .Warn:
            print("LDK LOG - Warn:")
            print("\(arguments)\n")
        case .Error:
            print("LDK LOG - Error:")
            print("\(arguments)\n")
        case .Gossip:
            break //print("\nGossip Logger:\n>\(arguments)\n")
        case .Trace:
            print("LDK LOG - Trace:")
            print("\(arguments)\n")
        default:
            print("LDK LOG - Unknown:")
            print("\(arguments)\n")
        }
    }
}
