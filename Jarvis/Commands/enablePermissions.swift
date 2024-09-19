//
//  enablePermissions.swift
//  Jarvis
//
//  Created by Sergio Daniel on 19/09/24.
//

import BankaiCore
import Combine
import EventKit
import CombineExt

func enablePermissionsCommand() -> AnyPublisher<String, Error> {
    .create { receiver in
        let eventStore = EKEventStore()
        
        receiver.send("Requesting permissions...")
        eventStore.requestFullAccessToEvents { granted, error in
            if let error {
                receiver.send(completion: .failure(
                    JarvisError.nestedError(error)
                ))
                return
            }
            
            if granted {
                receiver.send("Permission granted.")
                receiver.send(completion: .finished)
            } else {
                receiver.send(completion: .failure(
                    JarvisError.stringError("Permission Denied")
                ))
            }
        }
        
        return AnyCancellable {  }
    }
}
