//
//  Exposable.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//
import Foundation


/// 타입을 `ExposableObject`로 변환하는 매크로입니다.
///
/// `@Exposable`은 SwiftUI Observation과 `@Exposed` 프로퍼티 래퍼를
/// 통합하는 데 필요한 보일러플레이트를 자동 생성합니다.
///
/// 이 매크로를 적용하면 대상 타입은 다음을 보장합니다.
/// - `ExposableObject` 준수
/// - 안정적인 `ObservationRegistrar` 인스턴스(`registrar`) 보유
///
/// 이는 `@Exposed`가 SwiftUI Observation 시스템에서 읽기 접근을 올바르게
/// 등록하고 추적 가능한 변경을 수행하기 위해 필요합니다.
///
/// ---
///
/// ### 매크로 확장 (개념)
/// ```swift
/// // 1) 프로토콜 준수 추가
/// extension MyType: ExposableObject {}
///
/// // 2) registrar 저장 프로퍼티 주입
/// @ObservationIgnored
/// public let registrar = ObservationRegistrar()
/// ```
///
/// ---
///
/// ### 사용 예시
/// ```swift
/// @available(iOS 17.0, *)
/// @Exposable
/// final class ExampleViewModel {
///     @Exposed var value: Int = 0
/// }
/// ```
///
/// 확장 후에는 수동으로 registrar를 연결하지 않아도
/// `ExampleViewModel`이 `@Exposed`의 요구 사항을 충족합니다.
@attached(member, names: named(registrar))
@attached(extension, conformances: ExposableObject)
public macro Exposable() = #externalMacro(module: "ExposeMacros", type: "ExposableMacro")
