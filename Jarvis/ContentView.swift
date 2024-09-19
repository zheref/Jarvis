//
//  ContentView.swift
//  Jarvis
//
//  Created by Sergio Daniel on 19/09/24.
//

import BankaiCore
import Combine
import SwiftUI


func voidCommand() -> AnyPublisher<String, Never> {
    return .create { emit in
        emit(.complete)
        return AnyCancellable { }
    }
}

func everySecondTextCommand() -> AnyPublisher<String, Never> {
    return 60
        .secondsCounter()
        .map { "Ticked for \($0) seconds" }
        .eraseToAnyPublisher()
}

enum CommandScreen: CaseIterable {
    case enablePermissions
    case duplicateCorporates
    case removeAllDuplicates
    case settings
    
    var title: String {
        switch self {
        case .enablePermissions: return "Enable Permissions"
        case .duplicateCorporates: return "Duplicate Corporates"
                .capitalized
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
        case .removeAllDuplicates: return "trash"
        case .settings: return "gearshape"
        }
    }
    
    var flow: AnyPublisher<String, Never> {
        switch self {
        case .duplicateCorporates:
            return duplicateCorporatesCommand()
        default:
            return voidCommand()
        }
    }
}

struct ContentView: View {
    
    @State var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State var currentCommand: CommandScreen = .duplicateCorporates
    
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
        } detail: {
            detailFor(command: currentCommand)
        }

    }
    
    @ViewBuilder
    func detailFor(command: CommandScreen) -> some View {
        CommandView(commandFlow: command.flow)
            .frame(maxWidth: .infinity)
            .padding(.all, 7)
            .navigationTitle(command.title)
    }
}

#Preview {
    ContentView()
}
