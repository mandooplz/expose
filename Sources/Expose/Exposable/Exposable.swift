//
//  Exposable.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//
import Foundation


@attached(member, names: named(objectWillChange), named(registrar))
@attached(extension, conformances: ExposableObject, ExposableObservationObject)
public macro Exposable() = #externalMacro(module: "ExposeMacros", type: "ExposableMacro")
