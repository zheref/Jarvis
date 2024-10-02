//
//  CommandView.swift
//  Jarvis
//
//  Created by Sergio Daniel on 19/09/24.
//

import SwiftUI
import Combine
import JarvisLib

struct CommandView: View {
    
    var flowBuilder: CommandFlowBuilder
    
    @State var lines: [String] = [
        "Ready."
    ]
    @State var performance: CommandFlowConfig.PerformanceClass = .simulation
    
    @State var cancellables: Set<AnyCancellable> = []
    
    var currentTimestamp: String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentDate)
    }
    
    var body: some View {
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    ForEach(lines, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 10))
                            .monospaced()
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .defaultScrollAnchor(.bottom)
        .frame(maxWidth: .infinity)
        .toolbar {
            ToolbarItem {
                Menu {
                    ForEach(CommandFlowConfig.PerformanceClass.allCases) { it in
                        Button {
                            performance = it
                        } label: {
                            HStack {
                                if (performance == it) {
                                    Image(systemName: "checkmark")
                                }
                                Text(it.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(performance.rawValue)
                    }
                }
                .menuStyle(BorderlessButtonMenuStyle())
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    flowBuilder(.init(
                        performanceClass: performance
                    ))
                    .subscribe(on: DispatchQueue.main)
                    .catch {
                        Just(
                            "ERROR: \($0.localizedDescription)"
                        )
                    }
                    .print()
                    .sink { _ in lines.append("[\(currentTimestamp)] Completed.") }
                    receiveValue: { lines.append("[\(currentTimestamp)] \($0)") }
                    .store(in: &cancellables)
                } label: {
                    Image(systemName: "play.fill")
                }
            }
        }
        .onAppear {
            lines.removeAll()
            lines.append("Ready.")
        }
    }
    
}

#Preview {
    NavigationStack {
        CommandView(flowBuilder: everySecondTextCommand)
            .padding(.all, 7)
            .navigationTitle("Random Command")
    }
}
