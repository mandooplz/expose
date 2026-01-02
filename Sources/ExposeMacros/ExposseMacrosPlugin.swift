//
//  ExposseMacrosPlugin.swift
//  Expose
//
//  Created by 김민우 on 1/3/26.
//


import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftCompilerPlugin


@main
struct ExposseMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ExposableMacro.self,
    ]
}
