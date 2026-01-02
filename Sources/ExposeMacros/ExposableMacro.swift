//
//  ExposableMacro.swift
//  Expose
//
//  Created by 김민우 on 1/3/26.
//


import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftCompilerPlugin


public struct ExposableMacro: MemberMacro, ExtensionMacro {
    // ExtensionMacro: NewExposable 프로토콜 채택
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
        providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
        conformingTo protocols: [SwiftSyntax.TypeSyntax],
        in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
            let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed): ExposableObject {}")
            let observationExtensionDecl = try ExtensionDeclSyntax(
                """
                @available(iOS 17.0, *)
                extension \(type.trimmed): ExposableObservationObject {}
                """
            )
            return [extensionDecl, observationExtensionDecl]
    }
    
    
    // MemberMacro: registrar 프로퍼티 주입
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return [
            """
            public let objectWillChange = Combine.ObservableObjectPublisher()
            """,
            """
            @available(iOS 17.0, *)
            @ObservationIgnored
            public let registrar = ObservationRegistrar()
            """
        ]
    }
}
