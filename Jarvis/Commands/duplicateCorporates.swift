//
//  duplicateCorporates.swift
//  Jarvis
//
//  Created by Sergio Daniel on 19/09/24.
//

import BankaiCore
import Combine
import CombineExt

func duplicateCorporatesCommand() -> AnyPublisher<String, Error> {
    .create { receiver in
        receiver.send("d")
        receiver.send(completion: .finished)
        
        return AnyCancellable {}
    }
}
