//
//  duplicateCorporates.swift
//  Jarvis
//
//  Created by Sergio Daniel on 19/09/24.
//

import BankaiCore
import Combine
import CombineExt
import EventKit

private func fetchEvents(usingStore store: EKEventStore) -> [EKEvent] {
    let startOfToday = Calendar.current.startOfDay(for: Date())
    let endOfToday = Calendar.current.date(
        byAdding: .day,
        value: 1,
        to: startOfToday
    ) ?? startOfToday
    let predicate = store.predicateForEvents(withStart: startOfToday,
                                             end: endOfToday,
                                             calendars: nil)
    return store.events(matching: predicate)
}

private func formatTime(fromDate date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

extension EKEvent {
    var seemsCorporate: Bool {
        calendar.title.contains("@") || calendar.source.title.contains("@")
    }
    
    func print(_ index: Int, usingPrinter print: (String) -> Void) {
        if let title = title {
            if let startDate = startDate, let endDate = endDate {
                print("(\(index+1)) \(title) \(formatTime(fromDate: startDate)) - \(formatTime(fromDate: endDate)) from \(calendar.title) in \(calendar.source.title)")
            } else if isAllDay {
                print("(\(index+1)) \(title) [All Day] from \(calendar.title) in \(calendar.source.title)")
            }
        }
    }
    
    func createDuplicate(forStore store: EKEventStore) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.notes = notes
        event.location = location
        
        if let businessCalendar = store.calendars(for: .event).first(
            where: { $0.title.contains("Business") }
        ) {
            event.calendar = businessCalendar
        } else {
            event.calendar = store.defaultCalendarForNewEvents
        }
        
        return event
    }
}

private func saveDuplicates(_ duplicates: [EKEvent],
                            toStore store: EKEventStore,
                            usingPrinter print: (String) -> Void) throws {
    for event in duplicates {
        print("Duplicating event with title: \(event.title ?? "nil")...")
        try store.save(event, span: .thisEvent)
    }
    
    print("Beware: Commiting all changes into actual calendar.")
    try store.commit()
}

private func areRepresentingSameEvent(_ event1: EKEvent, _ event2: EKEvent) -> Bool {
    event1.title == event2.title &&
    ((event1.startDate == event2.startDate &&
      event1.endDate == event2.endDate) || (event1.isAllDay && event2.isAllDay))
}

extension Array where Element == EKEvent {
    func hasDuplicate(ofEvent event: EKEvent) -> Bool {
        contains(where: { areRepresentingSameEvent($0, event) })
    }
}

func duplicateCorporatesCommand(_ config: CommandFlowConfig) -> CommandFlow {
    .create { receiver in
        let store = EKEventStore()
        receiver.send("Fetching events for today...")
        
        let allEvents = fetchEvents(usingStore: store)
        
        let nonCorporateEvents = allEvents
            .filter { $0.seemsCorporate == false }
        let corporateEvents = allEvents
            .filter(\.seemsCorporate)
        receiver.send("Found \(allEvents.count) events.")
        receiver.send("Found \(corporateEvents.count) corporate events.")
        
        receiver.send("Non Corporate Events: -------------------------------")
        for (index, event) in nonCorporateEvents.enumerated() {
            event.print(index, usingPrinter: receiver.send)
        }
        
        receiver.send("Corporate Events: -----------------------------------")
        for (index, event) in corporateEvents.enumerated() {
            event.print(index, usingPrinter: receiver.send)
        }
        
        let candidatesToDuplicate = corporateEvents.filter {
            nonCorporateEvents.hasDuplicate(ofEvent: $0) == false
        }
        
        receiver.send("Candidates to Duplicate: ------------------------------")
        for (index, event) in candidatesToDuplicate.enumerated() {
            event.print(index, usingPrinter: receiver.send)
        }
        
        // Actual Duplication
        if config.performanceClass == .execution {
            let duplicates = candidatesToDuplicate.map {
                $0.createDuplicate(forStore: store)
            }
            do {
                try saveDuplicates(duplicates, toStore: store, usingPrinter: receiver.send)
            } catch {
                receiver.send(completion: .failure(JarvisError.nestedError(error)))
            }
        } else {
            receiver.send("Simulation: Actions not performed.")
        }
        
        receiver.send(completion: .finished)
        
        return AnyCancellable {}
    }
}
