//
//  CommandFlow.swift
//  Jarvis
//
//  Created by Sergio Daniel on 9/19/24.
//

import Combine

public typealias CommandFlow = AnyPublisher<String, Error>

public enum JarvisError: Error {
    case stringError(String)
    case nestedError(any Error)
    
    var localizedDescription: String {
        switch self {
        case .stringError(let string): return string
        case .nestedError(let error): return error.localizedDescription
        }
    }
}

public struct CommandFlowConfig {
    
    public enum PerformanceClass: String, CaseIterable, Hashable, Identifiable {
        case simulation
        case execution
        
        public var id: String { rawValue }
    }
    
    var performanceClass: PerformanceClass = .simulation
    var shouldSaveLogs: Bool = false
    
    public init(
        performanceClass: PerformanceClass = .simulation,
        shouldSaveLogs: Bool = false
    ) {
        self.performanceClass = performanceClass
        self.shouldSaveLogs = shouldSaveLogs
    }
}

public typealias CommandFlowBuilder = (_ config: CommandFlowConfig) -> CommandFlow
