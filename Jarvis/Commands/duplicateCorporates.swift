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

func duplicateCorporatesCommand() -> AnyPublisher<String, Error> {
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
            if let title = event.title, let startDate = event.startDate, let endDate = event.endDate {
                receiver
                    .send(
                        "(\(index+1)) \(title) \(formatTime(fromDate: startDate)) - \(formatTime(fromDate: endDate)) from \(event.calendar.title) in \(event.calendar.source.title)"
                    )
            }
        }
        
        receiver.send("Corporate Events: -----------------------------------")
        for (index, event) in corporateEvents.enumerated() {
            if let title = event.title, let startDate = event.startDate, let endDate = event.endDate {
                receiver
                    .send(
                        "(\(index+1)) \(title) \(formatTime(fromDate: startDate)) - \(formatTime(fromDate: endDate)) from \(event.calendar.title) in \(event.calendar.source.title)"
                    )
            }
        }
        
        let candidatesToDuplicate = corporateEvents.filter {
            nonCorporateEvents.hasDuplicate(ofEvent: $0) == false
        }
        
        receiver.send("Candidates to Duplicate: ------------------------------")
        for (index, event) in candidatesToDuplicate.enumerated() {
            if let title = event.title, let startDate = event.startDate, let endDate = event.endDate {
                receiver
                    .send(
                        "(\(index+1)) \(title) \(formatTime(fromDate: startDate)) - \(formatTime(fromDate: endDate)) from \(event.calendar.title) in \(event.calendar.source.title)"
                    )
            }
        }
        
        receiver.send(completion: .finished)
        
        return AnyCancellable {}
    }
}
