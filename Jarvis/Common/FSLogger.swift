//
//  FSLogger.swift
//  Jarvis
//
//  Created by Sergio Daniel on 19/09/24.
//

import Foundation

struct FSLogger {
    
    var label: String
    var filePath: URL
    
    init(label: String, filePath: URL? = nil) {
        self.label = label
        if let filePath {
            self.filePath = filePath
        } else {
            guard let userDirectory = FileManager.default.urls(
                for: .userDirectory,
                in: .userDomainMask
            ).first else {
                self.filePath = .applicationDirectory
                return
            }
            
            let currentTimestamp = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestampString = formatter.string(from: currentTimestamp)
            self.filePath = userDirectory
                .appendingPathComponent("Jarvis")
                .appendingPathComponent("\(label) [\(timestampString)].log")
        }
    }
    
    func write(_ line: String) {
        do {
            if let fileHandle = try? FileHandle(forWritingTo: filePath) {
                fileHandle.seekToEndOfFile()
                if let data = line.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                try line.write(to: filePath, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Failed to write to file: \(error)")
        }
    }
    
}
