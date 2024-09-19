//
//  enablePermissions.swift
//  Jarvis
//
//  Created by Sergio Daniel on 19/09/24.
//

import BankaiCore
import Combine
import EventKit

func enablePermissionsCommand() -> AnyPublisher<String, Error> {
    .create { (emit: @escaping ((ZEvent<String, Error>) -> Void)) in
        let eventStore = EKEventStore()
        
        eventStore.requestFullAccessToEvents { granted, error in
            if let error {
                emit(.failure(JarvisError.nestedError(error)))
                return
            }
            
            if granted {
                emit(.value("Permission granted."))
                emit(.complete)
            } else {
                emit(.failure(JarvisError.stringError("Permission Denied")))
            }
        }
        
        return AnyCancellable {  }
    }
}
