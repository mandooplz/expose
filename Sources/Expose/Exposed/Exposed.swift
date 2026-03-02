//
//  Exposed.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//


import RxCocoa
@_exported import Combine

/// **SwiftUI Observation**, **RxSwift**, **Combine**을 연결하는 통합 상태 프로퍼티 래퍼입니다.
///
/// `@Exposed`는 상태를 단일 진실 공급원으로 선언하면서도,
/// 여러 반응형 시스템으로 상태를 노출할 수 있게 해줍니다.
/// - enclosing-instance subscript를 통한 **SwiftUI Observation**
/// - `BehaviorRelay`를 통한 **RxSwift**
/// - projected publisher를 통한 **Combine**
///
/// 이 설계는 상태 중복 없이 UIKit(RxSwift), SwiftUI(Observation),
/// Combine 기반 아키텍처 사이를 점진적으로 마이그레이션할 수 있게 합니다.
///
/// ---
///
/// ### 사용 예시
/// ```swift
/// @available(iOS 17.0, *)
/// final class CounterViewModel: ExposableObject {
///     @Exposed var count: Int = 0
///
///     func increment() {
///         count += 1
///     }
/// }
/// ```
///
/// - SwiftUI가 `count`의 읽기/쓰기를 자동 추적합니다.
/// - `$count.rx`는 RxSwift 스트림을 노출합니다.
/// - `$count.publisher`는 Combine publisher를 노출합니다.
///
/// ---
///
/// ### 요구 사항
/// - enclosing 타입은 **반드시 `ExposableObject`를 준수해야 합니다.**
/// - **클래스 타입**에서만 지원됩니다.
/// - Observation 통합을 위해 **iOS 17+**가 필요합니다.
///
/// ---
///
/// ### 설계 노트
/// - 내부적으로 `BehaviorRelay`를 사용해 동기식 값 접근을 보장합니다.
/// - 변경은 `ObservationRegistrar.withMutation`으로 감싸
///   SwiftUI invalidation 시맨틱을 올바르게 보장합니다.
///
/// 이 프로퍼티 래퍼는 Observation의 정의되지 않은 동작을 피하기 위해
/// 값 타입(`struct`)에서는 의도적으로 사용할 수 없습니다.
@available(iOS 17.0, *)
@propertyWrapper
public struct Exposed<T> {
    private var relay: BehaviorRelay<T>

    public init(wrappedValue: T) {
        self.relay = BehaviorRelay(value: wrappedValue)
    }

    /// 이 상태에 대한 RxSwift/Combine 스트림 접근을 제공합니다.
    ///
    /// `$` 접두어로 접근합니다.
    /// ```swift
    /// viewModel.$count.rx
    /// viewModel.$count.publisher
    /// ```
    public var projectedValue: ExposedStream<T> {
        ExposedStream(relay: relay)
    }

    /// SwiftUI를 위한 Observation 통합 접근자입니다.
    ///
    /// `@Exposed`가 `ExposableObject`를 준수하는 클래스의 저장 프로퍼티에
    /// 적용되면 이 subscript가 컴파일러에 의해 생성됩니다.
    ///
    /// ### 동작 방식
    /// - **Get**: `ObservationRegistrar`에 읽기 접근을 등록합니다.
    /// - **Set**: 추적 가능한 변경을 수행하고 새 값을
    ///   모든 반응형 백엔드(Observation, RxSwift, Combine)로 전파합니다.
    ///
    /// ### 예시
    /// ```swift
    /// @available(iOS 17.0, *)
    /// final class ExampleViewModel: ExposableObject {
    ///     @Exposed var value: Int = 0
    ///
    ///     func update() {
    ///         value += 1   // Observation + Rx + Combine 업데이트 트리거
    ///     }
    /// }
    ///
    /// let vm = ExampleViewModel()
    /// let disposable = vm.$value.rx
    ///     .subscribe(onNext: { print($0) })
    ///
    /// vm.update() // 변경된 값 출력
    /// ```
    ///
    /// 이 메커니즘을 통해 `@Exposed`는 RxSwift/Combine 기반을 유지하면서도
    /// SwiftUI Observation 시스템에 완전히 참여할 수 있습니다.
    public static subscript<EnclosingSelf: ExposableObject> (
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Exposed<T>>
    ) -> T {
        get {
            // SwiftUI Observation용 읽기 접근 등록
            instance.registrar.access(instance, keyPath: wrappedKeyPath)
            return instance[keyPath: storageKeyPath].relay.value
        }
        set {
            // 추적 가능한 변경을 수행하고 새 값을 전파
            instance.registrar.withMutation(of: instance, keyPath: wrappedKeyPath) {
                instance[keyPath: storageKeyPath].relay.accept(newValue)
            }
        }
    }

    /// wrapped value 직접 접근을 방지합니다.
    ///
    /// 올바른 Observation 및 반응형 전파 시맨틱을 보장하기 위해
    /// enclosing-instance subscript를 통해서만 접근해야 합니다.
    @available(*, unavailable, message: "@Exposed can only be accessed on ExposableObject classes")
    public var wrappedValue: T {
        get { fatalError() }
        set { fatalError() }
    }
}
