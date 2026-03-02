//
//  ExposedStream.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//


import RxCocoa
import RxCombine
import Combine


/// `@Exposed` 값의 반응형 프로젝션입니다.
///
/// `ExposedStream`은 `@Exposed`의 `$`(projected) 값으로 반환되며,
/// 동일한 기본 상태에 대해 여러 패러다임으로 편리한 접근을 제공합니다.
/// - `Driver`를 통한 **RxSwift**
/// - `AnyPublisher`를 통한 **Combine**
/// - `AsyncPublisher`를 통한 **Swift Concurrency**
///
/// ### 사용 예시
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
/// `ExposedStream`은 단일 진실 공급원을 wrapped 프로퍼티(`@Exposed var ...`)에
/// 유지하기 위해 읽기 전용 스트림만 의도적으로 노출합니다.
public struct ExposedStream<T> {
    private let relay: BehaviorRelay<T>
    
    init(relay: BehaviorRelay<T>) {
        self.relay = relay
    }
    
    /// 현재 값을 방출하는 RxSwift `Driver` 스트림입니다.
    ///
    /// - 메인 스레드 전달을 보장합니다.
    /// - 부수 효과를 공유하며 에러를 방출하지 않습니다.
    ///
    /// ### 예시
    /// ```swift
    /// viewModel.$count.driver
    ///     .drive(onNext: { print($0) })
    ///     .disposed(by: disposeBag)
    /// ```
    public var driver: Driver<T> {
        return relay.asDriver()
    }
    
    /// 현재 값을 방출하는 Combine `AnyPublisher` 스트림입니다.
    ///
    /// 이 publisher는 실패하지 않으며(`Never`) 동일한 기본 relay를 사용합니다.
    ///
    /// ### 예시
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

    /// Combine publisher(`publisher.values`)의 async sequence 뷰입니다.
    ///
    /// ### 예시
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
