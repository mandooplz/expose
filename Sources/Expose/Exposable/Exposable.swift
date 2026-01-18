//
//  Exposable.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//
import Foundation


/// A macro that transforms a type into an `ExposableObject`.
///
/// `@Exposable` synthesizes the boilerplate required to integrate
/// SwiftUI Observation with the `@Exposed` property wrapper.
///
/// Applying this macro guarantees that the annotated type:
/// - Conforms to `ExposableObject`
/// - Owns a stable `ObservationRegistrar` instance (`registrar`)
///
/// This is required for `@Exposed` to correctly register reads and perform
/// tracked mutations under SwiftUI's Observation system.
///
/// ---
///
/// ### Macro Expansion (Conceptual)
/// ```swift
/// // 1) Adds protocol conformance
/// extension MyType: ExposableObject {}
///
/// // 2) Injects a registrar stored property
/// @ObservationIgnored
/// public let registrar = ObservationRegistrar()
/// ```
///
/// ---
///
/// ### Usage
/// ```swift
/// @available(iOS 17.0, *)
/// @Exposable
/// final class ExampleViewModel {
///     @Exposed var value: Int = 0
/// }
/// ```
///
/// After expansion, `ExampleViewModel` satisfies the requirements needed by
/// `@Exposed` without any manual registrar wiring.
@attached(member, names: named(registrar))
@attached(extension, conformances: ExposableObject)
public macro Exposable() = #externalMacro(module: "ExposeMacros", type: "ExposableMacro")
