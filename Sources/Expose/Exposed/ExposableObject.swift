//
//  ExposableObject.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//


@_exported import Observation
@_exported import Combine



@available(iOS 17.0, *)
public protocol ExposableObject: AnyObject, Observation.Observable, ObservableObject {
    var registrar: ObservationRegistrar { get }
}
