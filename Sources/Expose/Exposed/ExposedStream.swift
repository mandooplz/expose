//
//  ExposedStream.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//


import RxCocoa
import RxCombine
import Combine


/// A reactive projection of an `@Exposed` value.
///
/// `ExposedStream` is returned from the `$` (projected) value of `@Exposed` and provides
/// convenient access to the same underlying state through multiple paradigms:
/// - **RxSwift** via `Driver`
/// - **Combine** via `AnyPublisher`
/// - **Swift Concurrency** via `AsyncPublisher`
///
/// ### Usage
/// ```swift
/// @available(iOS 17.0, *)
/// final class CounterViewModel: ExposableObject {
///     @Exposed var count: Int = 0
/// }
///
/// let vm = CounterViewModel()
///
/// // RxSwift
/// let disposable = vm.$count.driver
///     .drive(onNext: { print("count:", $0) })
///
/// // Combine
/// let cancellable = vm.$count.publisher
///     .sink { print("count:", $0) }
///
/// // Swift Concurrency
/// Task {
///     for await value in vm.$count.values {
///         print("count:", value)
///     }
/// }
/// ```
///
/// `ExposedStream` intentionally exposes read-only streams to keep the single source of truth
/// on the wrapped property (`@Exposed var ...`).
public struct ExposedStream<T> {
    private let relay: BehaviorRelay<T>
    
    init(relay: BehaviorRelay<T>) {
        self.relay = relay
    }
    
    /// An RxSwift `Driver` stream of the current value.
    ///
    /// - Guarantees delivery on the main thread
    /// - Shares side effects and never errors
    ///
    /// ### Example
    /// ```swift
    /// viewModel.$count.driver
    ///     .drive(onNext: { print($0) })
    ///     .disposed(by: disposeBag)
    /// ```
    public var driver: Driver<T> {
        return relay.asDriver()
    }
    
    /// A Combine `AnyPublisher` stream of the current value.
    ///
    /// The publisher never fails (`Never`) and is backed by the same underlying relay.
    ///
    /// ### Example
    /// ```swift
    /// viewModel.$count.publisher
    ///     .sink { print($0) }
    ///     .store(in: &cancellables)
    /// ```
    public var publisher: AnyPublisher<T, Never> {
        return relay.asObservable()
            .asPublisher()
            .catch { _ in Empty<T, Never>() }
            .eraseToAnyPublisher()
    }

    /// An async sequence view of the Combine publisher (`publisher.values`).
    ///
    /// ### Example
    /// ```swift
    /// Task {
    ///     for await value in viewModel.$count.values {
    ///         print(value)
    ///     }
    /// }
    /// ```
    public var values: AsyncPublisher<AnyPublisher<T, Never>> {
        publisher.values
    }
}
