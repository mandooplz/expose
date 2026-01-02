//
//  Exposable.swift
//  Expose
//
//  Created by 김민우 on 1/2/26.
//
import Foundation


@attached(member, names: named(registrar))
@attached(extension, conformances: UnifiedObservable)
public macro Exposable() = #externalMacro(module: "ExposeMacros", type: "ExposableMacro")
