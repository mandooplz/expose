//
//  ExposedStream.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//


import RxCocoa
import RxCombine
import Combine

public struct ExposedStream<T> {
    private let relay: BehaviorRelay<T>
    
    init(relay: BehaviorRelay<T>) {
        self.relay = relay
    }
    
    /// RxSwift의 Driver (Main Thread 보장)
    public var driver: Driver<T> {
        return relay.asDriver()
    }
    
    /// Combine의 AnyPublisher
    public var publisher: AnyPublisher<T, Never> {
        return relay.asObservable()
            .asPublisher()
            .catch { _ in Empty<T, Never>() }
            .eraseToAnyPublisher()
    }
}
