//
//  Main.swift
//  Jarvis
//
//  Created by Sergio Daniel on 10/2/24.
//

import Combine
import Foundation
import JarvisLib

@main
struct JarvisCLI {
    static var disposeBag = Set<AnyCancellable>()
    
    static var currentTimestamp: String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentDate)
    }
    
    static func main() {
        print("Hello Jarvis CLI with Own Framework!")
//        if CommandLine.arguments.contains("--enable-permissions") {
//            
//        }
        
        let enablePermissionsCF = enablePermissionsCommand(
            CommandFlowConfig(performanceClass: .simulation,
                              shouldSaveLogs: true)
        )
        
        enablePermissionsCF
            .subscribe(on: RunLoop.main)
            .catch {
                Just(
                    "ERROR: \($0.localizedDescription)"
                )
            }
            .print()
            .sink { _ in print("[\(currentTimestamp)] Completed.") }
            receiveValue: { print("[\(currentTimestamp)] \($0)") }
            .store(in: &disposeBag)
        
        
        print("Staying in the loop...")
        RunLoop.main.run(until: .distantFuture)
        print("Ended the loop.")
    }
}
