//
//  ContentView.swift
//  Jarvis
//
//  Created by Sergio Daniel on 19/09/24.
//

import BankaiCore
import Combine
import SwiftUI

enum JarvisError: Error {
    case stringError(String)
    case nestedError(any Error)
    
    var localizedDescription: String {
        switch self {
        case .stringError(let string): return string
        case .nestedError(let error): return error.localizedDescription
        }
    }
}

func voidCommand() -> AnyPublisher<String, Error> {
    return .create { receiver in
        receiver.send(completion: .finished)
        return AnyCancellable { }
    }
}

func everySecondTextCommand(_ config: CommandFlowConfig) -> CommandFlow {
    return 60
        .secondsCounter()
        .map { "Ticked for \($0) seconds" }
        .setFailureType(to: Error.self)
        .eraseToAnyPublisher()
}

enum CommandScreen: CaseIterable {
    case enablePermissions
    case duplicateCorporates
    case slotTodayPomos
    case slotTomorrowPomos
    case removeAllDuplicates
    case settings
    
    var title: String {
        switch self {
        case .enablePermissions: return "Enable Permissions"
        case .duplicateCorporates: return "Duplicate Corporates"
                .capitalized
        case .slotTodayPomos: return "Slot Today's Pomos"
                .capitalized
        case .slotTomorrowPomos: return "Slot Tomorrow's Pomos"
        case .removeAllDuplicates: return "Remove All Duplicates"
                .capitalized
        case .settings: return "Settings"
                .capitalized
        }
    }
    
    var glyph: String {
        switch self {
        case .enablePermissions: return "lock.circle"
        case .duplicateCorporates: return "person.2.circle"
        case .slotTodayPomos: return "clock.badge.checkmark"
        case .slotTomorrowPomos: return "calendar.badge.clock"
        case .removeAllDuplicates: return "trash"
        case .settings: return "gearshape"
        }
    }
    
    var flow: CommandFlowBuilder {
        switch self {
        case .enablePermissions:
            return enablePermissionsCommand
        case .duplicateCorporates:
            return duplicateCorporatesCommand
        case .slotTodayPomos:
            return slotPomosCommand(referenceDate: Date())
        case .slotTomorrowPomos:
            return slotPomosCommand(referenceDate: Date().oneDayOut)
        default:
            return everySecondTextCommand
        }
    }
}

struct ContentView: View {
    
    @State var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State var currentCommand: CommandScreen = .enablePermissions
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $currentCommand) {
                ForEach(CommandScreen.allCases, id: \.hashValue) { command in
                    NavigationLink(value: command) {
                        HStack {
                            Image(systemName: command.glyph)
                            Text(command.title)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
            .navigationSplitViewStyle(ProminentDetailNavigationSplitViewStyle())
        } detail: {
            detailFor(command: currentCommand)
        }
    }
    
    @ViewBuilder
    func detailFor(command: CommandScreen) -> some View {
        CommandView(flowBuilder: command.flow)
            .frame(maxWidth: .infinity)
            .padding(.all, 7)
            .navigationTitle(command.title)
    }
}

#Preview {
    ContentView()
}
