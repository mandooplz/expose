//
//  ExposableObject.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//


import Combine
import Observation


public protocol ExposableObject: AnyObject, ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {}

@available(iOS 17.0, *)
public protocol ExposableObservationObject: ExposableObject, Observation.Observable {
    var registrar: ObservationRegistrar { get }
    func exposedAccess(_ keyPath: AnyKeyPath)
    func exposedWithMutation(_ keyPath: AnyKeyPath, _ mutation: () -> Void)
}

@available(iOS 17.0, *)
public extension ExposableObservationObject {
    func exposedAccess(_ keyPath: AnyKeyPath) {
        guard let typedKeyPath = keyPath as? KeyPath<Self, Any> else {
            assertionFailure("KeyPath root does not match \(Self.self)")
            return
        }
        registrar.access(self, keyPath: typedKeyPath)
    }

    func exposedWithMutation(_ keyPath: AnyKeyPath, _ mutation: () -> Void) {
        guard let typedKeyPath = keyPath as? KeyPath<Self, Any> else {
            assertionFailure("KeyPath root does not match \(Self.self)")
            mutation()
            return
        }
        registrar.withMutation(of: self, keyPath: typedKeyPath, mutation)
    }
}
