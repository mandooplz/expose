//
//  Exposed.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//


import RxCocoa
@_exported import Combine


@propertyWrapper
public struct Exposed<T> {
    private var relay: BehaviorRelay<T>

    public init(wrappedValue: T) {
        self.relay = BehaviorRelay(value: wrappedValue)
    }

    /// $ 기호를 통해 Rx/Combine 스트림에 접근
    public var projectedValue: ExposedStream<T> {
        ExposedStream(relay: relay)
    }

    /// 핵심: Observation 통합 서브스크립트
    /// EnclosingSelf가 NewExposable을 채택하고 있어야 registrar에 접근 가능합니다.
    public static subscript<EnclosingSelf: ExposableObject> (
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, T>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Exposed<T>>
    ) -> T {
        get {
            if #available(iOS 17.0, *), let observationInstance = instance as? ExposableObservationObject {
                // SwiftUI가 이 값을 읽을 때 감지 (Tracking)
                observationInstance.exposedAccess(wrappedKeyPath)
            }
            return instance[keyPath: storageKeyPath].relay.value
        }
        set {
            if #available(iOS 17.0, *), let observationInstance = instance as? ExposableObservationObject {
                // SwiftUI에게 이 값이 바뀔 것임을 알림 (Mutation)
                observationInstance.exposedWithMutation(wrappedKeyPath) {
                    instance[keyPath: storageKeyPath].relay.accept(newValue)
                }
            } else {
                instance.objectWillChange.send()
                instance[keyPath: storageKeyPath].relay.accept(newValue)
            }
        }
    }

    /// 값 타입(Struct)에서의 사용을 제한하고 클래스 멤버로 유도
    @available(*, unavailable, message: "사용 불가")
    public var wrappedValue: T {
        get { fatalError() }
        set { fatalError() }
    }
}
