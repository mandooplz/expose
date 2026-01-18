//
//  Exposed.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//


import RxCocoa
@_exported import Combine

/// A unified state property wrapper that bridges **SwiftUI Observation**, **RxSwift**, and **Combine**.
///
/// `@Exposed` allows you to declare a single source of truth for state, while
/// exposing that state through multiple reactive systems:
/// - **SwiftUI Observation** via the enclosing-instance subscript
/// - **RxSwift** via `BehaviorRelay`
/// - **Combine** via the projected publisher
///
/// This design enables gradual migration between UIKit (RxSwift),
/// SwiftUI (Observation), and Combine-based architectures without duplicating state.
///
/// ---
///
/// ### Usage
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
/// - SwiftUI automatically tracks reads and writes to `count`
/// - `$count.rx` exposes an RxSwift stream
/// - `$count.publisher` exposes a Combine publisher
///
/// ---
///
/// ### Requirements
/// - The enclosing type **must conform to `ExposableObject`**
/// - Only supported on **class types**
/// - Requires **iOS 17+** for Observation integration
///
/// ---
///
/// ### Design Notes
/// - Internally backed by `BehaviorRelay` to guarantee synchronous value access
/// - Mutation is wrapped in `ObservationRegistrar.withMutation` to ensure
///   correct SwiftUI invalidation semantics
///
/// This property wrapper is intentionally unavailable for value types (`struct`)
/// to avoid undefined Observation behavior.
@available(iOS 17.0, *)
@propertyWrapper
public struct Exposed<T> {
    private var relay: BehaviorRelay<T>

    public init(wrappedValue: T) {
        self.relay = BehaviorRelay(value: wrappedValue)
    }

    /// Provides access to RxSwift and Combine streams for this state.
    ///
    /// Accessed using the `$` prefix:
    /// ```swift
    /// viewModel.$count.rx
    /// viewModel.$count.publisher
    /// ```
    public var projectedValue: ExposedStream<T> {
        ExposedStream(relay: relay)
    }

    /// Observation-integrated accessor for SwiftUI.
    ///
    /// This subscript is synthesized by the compiler when `@Exposed`
    /// is applied to a stored property on a class that conforms to
    /// `ExposableObject`.
    ///
    /// ### How It Works
    /// - **Get**: Registers a read access with `ObservationRegistrar`
    /// - **Set**: Executes a tracked mutation and publishes the new value
    ///   to all reactive backends (Observation, RxSwift, Combine)
    ///
    /// ### Example
    /// ```swift
    /// @available(iOS 17.0, *)
    /// final class ExampleViewModel: ExposableObject {
    ///     @Exposed var value: Int = 0
    ///
    ///     func update() {
    ///         value += 1   // Triggers Observation + Rx + Combine updates
    ///     }
    /// }
    ///
    /// let vm = ExampleViewModel()
    /// let disposable = vm.$value.rx
    ///     .subscribe(onNext: { print($0) })
    ///
    /// vm.update() // Prints updated value
    /// ```
    ///
    /// This mechanism allows `@Exposed` to fully participate in SwiftUI’s
    /// Observation system while remaining backed by RxSwift and Combine.
    public static subscript<EnclosingSelf: ExposableObject> (
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Exposed<T>>
    ) -> T {
        get {
            // Registers a read access for SwiftUI Observation
            instance.registrar.access(instance, keyPath: wrappedKeyPath)
            return instance[keyPath: storageKeyPath].relay.value
        }
        set {
            // Performs a tracked mutation and propagates the new value
            instance.registrar.withMutation(of: instance, keyPath: wrappedKeyPath) {
                instance[keyPath: storageKeyPath].relay.accept(newValue)
            }
        }
    }

    /// Prevents direct access to the wrapped value.
    ///
    /// Access must go through the enclosing-instance subscript to ensure
    /// correct Observation and reactive propagation semantics.
    @available(*, unavailable, message: "Not available")
    public var wrappedValue: T {
        get { fatalError() }
        set { fatalError() }
    }
}
