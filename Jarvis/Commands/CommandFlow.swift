//
//  CommandFlow.swift
//  Jarvis
//
//  Created by Sergio Daniel on 9/19/24.
//

import Combine

typealias CommandFlow = AnyPublisher<String, Error>

struct CommandFlowConfig {
    
    enum PerformanceClass: String, CaseIterable, Hashable, Identifiable {
        case simulation
        case execution
        
        var id: String { rawValue }
    }
    
    var performanceClass: PerformanceClass = .simulation
}

typealias CommandFlowBuilder = (_ config: CommandFlowConfig) -> CommandFlow
