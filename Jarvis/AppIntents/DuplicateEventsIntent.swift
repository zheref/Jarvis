//
//  DuplicateEventsIntent.swift
//  Jarvis
//
//  Created by Sergio Daniel on 19/09/24.
//

import AppIntents
import Combine

struct DuplicateEventsIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Duplicate Corporate Events"
    static var description = IntentDescription("Duplicates all events in Calendar that seem corporate to your default Business calendar to keep all your schedule in one place.")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
//        let publisher = duplicateCorporatesCommand(
//            .init(performanceClass: .simulation, shouldSaveLogs: false)
//        )
//        let commandTask = AsyncThrowingPublisher(publisher)
//        
//        //let logger = FSLogger(label: "DuplicateEventsIntent")
//        var linesLog = [String]()
//        
//        do {
//            for try await line in commandTask {
//                linesLog.append(line)
//                //logger.write(line)
//            }
//            
//            let dialog = IntentDialog("Success")
//            return .result(value: "Completed", dialog: dialog)
//        } catch {
//            let totalLines = linesLog.joined(separator: "\n")
//            let dialog = IntentDialog("Failure")
//            return .result(value: totalLines, dialog: dialog)
//        }
        
//        let dialog = IntentDialog("Success")
//        return .result(value: "Completed", dialog: dialog)
        
        return .result()
    }
    
}
