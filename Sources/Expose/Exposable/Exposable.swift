//
//  Exposable.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//
import Foundation
import Combine


@attached(member, names: named(registrar))
@attached(extension, conformances: NewExposableObject, Combine.ObservableObject)
public macro Exposable() = #externalMacro(module: "ExposeMacros", type: "ExposableMacro")
