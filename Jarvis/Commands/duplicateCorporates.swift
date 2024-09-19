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

func duplicateCorporatesCommand() -> AnyPublisher<String, Error> {
    .create { receiver in
        let store = EKEventStore()
        receiver.send("Fetching events for today...")
        
        let events = fetchEvents(usingStore: store)
        receiver.send("Found \(events.count) events.")
        
        for (index, event) in events.enumerated() {
            if let title = event.title, let startDate = event.startDate, let endDate = event.endDate {
                receiver
                    .send(
                        "(\(index+1)) \(title) \(formatTime(fromDate: startDate)) - \(formatTime(fromDate: endDate)) from \(event.calendar.title)"
                    )
            }
            
        }
        
        receiver.send(completion: .finished)
        
        return AnyCancellable {}
    }
}
