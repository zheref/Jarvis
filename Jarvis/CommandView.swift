//
//  CommandView.swift
//  Jarvis
//
//  Created by Sergio Daniel on 19/09/24.
//

import SwiftUI
import Combine

struct CommandView: View {
    
    var commandFlow: AnyPublisher<String, Error>
    
    @State var lines: [String] = [
        "Ready."
    ]
    
    @State var cancellables: Set<AnyCancellable> = []
    
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
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    commandFlow
                        .subscribe(on: DispatchQueue.main)
                        .catch {
                            Just("ERROR: \($0.localizedDescription)")
                        }
                        .print()
                        .sink { _ in lines.append("Completed.") }
                            receiveValue: { lines.append($0) }
                        .store(in: &cancellables)
                }) {
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
        CommandView(commandFlow: everySecondTextCommand())
            .padding(.all, 7)
            .navigationTitle("Random Command")
    }
}
