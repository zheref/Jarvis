//
//  slotPomos.swift
//  Jarvis
//
//  Created by Sergio Daniel on 9/19/24.
//

import BankaiCore
import Combine
import EventKit

extension EKEvent {
    static func new(title: String,
                    start: Date,
                    duration: TimeInterval,
                    onStore store: EKEventStore) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = start
        event.endDate = start.addingTimeInterval(duration)
        return event
    }
    
    var isBlocking: Bool {
        return true
    }
}

func fetchEventsForDay(startingAt startRef: Date, usingStore store: EKEventStore) -> [EKEvent] {
    let startOfToday = Calendar.current.startOfDay(for: startRef)
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

private func timebox(_ n: Int,
                     labeled label: String,
                     downSince since: Date = Date(),
                     within events: [EKEvent],
                     minDuration: TimeInterval,
                     maxDuration: TimeInterval,
                     upUntil until: Date,
                     onStore store: EKEventStore) -> [EKEvent] {
    var generatedBoxes = [EKEvent]()
    
    // Ensure events are filtered
    let blockingEvents: [EKEvent] = events
        .filter(\.isBlocking)
        .filter { !$0.isAllDay }
        .filter { $0.endDate != nil && $0.startDate != nil }
        .filter { $0.endDate! >= since }
        .filter { $0.startDate! < until }
    
    if blockingEvents.isEmpty {
        // Flow in case there are no scheduled events today
        var generatedCount = 0
        var leadingBoundary = since
        var availableTime = until.timeIntervalSince(leadingBoundary)
        
        while availableTime >= minDuration && generatedCount < n {
            let proposedTime = availableTime <= maxDuration ? availableTime : maxDuration
            let availableSegmentsCount = Int(proposedTime / minDuration)
            let totalSessionDuration = minDuration * TimeInterval(availableSegmentsCount)
            
            // Slot time
            generatedCount += 1
            let box: EKEvent = .new(
                title: "\(label) #\(generatedCount)",
                start: leadingBoundary,
                duration: totalSessionDuration,
                onStore: store
            )
            generatedBoxes.append(box)
            
            // Prepare to repeat (if possible)
            availableTime -= totalSessionDuration
            leadingBoundary = box.endDate
        }
        
        return generatedBoxes
    }

    // TODO: Create method exclusively to arrange correctly events and do unit tests for it
    let sortedEvents = blockingEvents.sorted(by: {
        if $0.startDate == $1.startDate {
            return $0.endDate! < $1.endDate!
        } else {
            if $0.startDate! < $1.startDate! {
                if $0.endDate! < $1.endDate! {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    })

    var generatedCount = 0
    
    for index in (-1..<sortedEvents.count) {
        var leadingBoundary = index >= 0 ? sortedEvents[index].endDate : since

        guard var leadingBoundary else {
            // TODO: Throw error here
            return []
        }

        let nextEvent = sortedEvents[safe: index + 1]
        let trailingBoundary = nextEvent?.startDate ?? until

        var availableTime = trailingBoundary.timeIntervalSince(leadingBoundary)

        while availableTime >= minDuration && generatedCount < n {
            let proposedTime = availableTime <= maxDuration ? availableTime : maxDuration
            let availableSegmentsCount = Int(proposedTime / minDuration)
            let totalSessionDuration = minDuration * TimeInterval(availableSegmentsCount)
            
            // Slot time
            generatedCount += 1
            let box: EKEvent = .new(
                title: "\(label) #\(generatedCount)",
                start: leadingBoundary,
                duration: totalSessionDuration,
                onStore: store
            )
            generatedBoxes.append(box)
            
            // Prepare to repeat (if possible)
            availableTime -= totalSessionDuration
            leadingBoundary = box.endDate
        }
        
        if generatedCount >= n { break } else { continue }
    }
    
    return generatedBoxes
}

private func save(sessions: [EKEvent], onto store: EKEventStore, usingPrinter print: (String) -> Void) throws {
    for session in sessions {
        print("Saving proposed session: \(session.title ?? "nil") to real calendar...")
        try store.save(session, span: .thisEvent)
    }
    print("Beware: Commiting all changes into real calendar.")
    try store.commit()
}

func slotPomosCommand(startStamp: Date = Date()) -> CommandFlowBuilder {
    return { config in
        .create { receiver in
            let store = EKEventStore()
            let presentEvents = fetchEventsForDay(startingAt: startStamp, usingStore: store)
                .filter { $0.isAllDay == false }
            receiver.send("Found \(presentEvents.count) present blocking events.")
            receiver.send("Blocking Events: -----------------------------")
            for (index, event) in presentEvents.enumerated() {
                event.print(index, usingPrinter: receiver.send)
            }
            
            let proposedSessionsR = timebox(1,
                                           labeled: "Get Ready",
                                           downSince: startStamp,
                                           within: presentEvents,
                                           minDuration: 30.minutes,
                                           maxDuration: 30.minutes,
                                           upUntil: .endOfDay(from: startStamp),
                                           onStore: store)
            
            receiver.send("Proposed Sessions for Getting Ready: ----------------------------")
            for (index, session) in proposedSessionsR.enumerated() {
                session.calendar = store.defaultCalendarForNewEvents
                session.print(index, usingPrinter: receiver.send)
            }
            
            let proposedSessionsA = timebox(7,
                                           labeled: "Session A",
                                           downSince: startStamp,
                                           within: presentEvents + proposedSessionsR,
                                           minDuration: 30.minutes,
                                           maxDuration: 30.minutes,
                                           upUntil: .endOfDay(from: startStamp),
                                           onStore: store)
            
            receiver.send("Proposed Sessions for A: ----------------------------")
            for (index, session) in proposedSessionsA.enumerated() {
                session.calendar = store.defaultCalendarForNewEvents
                session.print(index, usingPrinter: receiver.send)
            }
            
            let proposedSessionsB = timebox(7,
                                           labeled: "Session B",
                                           downSince: startStamp,
                                           within: presentEvents + proposedSessionsR + proposedSessionsA,
                                           minDuration: 30.minutes,
                                           maxDuration: 30.minutes,
                                           upUntil: .endOfDay(from: startStamp),
                                           onStore: store)
            
            receiver.send("Proposed Sessions for B: ----------------------------")
            for (index, session) in proposedSessionsB.enumerated() {
                session.calendar = store.defaultCalendarForNewEvents
                session.print(index, usingPrinter: receiver.send)
            }
            
            if config.performanceClass == .execution {
                do {
                    try save(sessions: proposedSessionsR + proposedSessionsA + proposedSessionsB, onto: store, usingPrinter: receiver.send)
                } catch {
                    receiver.send(completion: .failure(JarvisError.nestedError(error)))
                }
            } else {
                receiver.send("Simulation: Actions not performed.")
            }
            
            return AnyCancellable { }
        }
    }
}
