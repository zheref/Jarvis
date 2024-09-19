//
//  duplicateCorporates.swift
//  Jarvis
//
//  Created by Sergio Daniel on 19/09/24.
//

import BankaiCore
import Combine

func duplicateCorporatesCommand() -> AnyPublisher<String, Error> {
    .create({ emit in
        emit(.value("d"))
        
        return AnyCancellable {}
    })
}
