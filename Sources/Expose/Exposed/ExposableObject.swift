//
//  ExposableObject.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//


import Observation


@available(iOS 17.0, *)
public protocol ExposableObject: AnyObject, Observation.Observable {
    var registrar: ObservationRegistrar { get }
}
