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
            // iOS 17 이상에서만 Observation.Observable을 채택하도록 생성
                let observationExtension = try ExtensionDeclSyntax("""
                @available(iOS 17.0, *)
                extension \(type.trimmed): NewExposableObject {}
                """)

                // 모든 버전에서 ObservableObject를 채택하도록 생성
                let legacyExtension = try ExtensionDeclSyntax("""
                extension \(type.trimmed): Combine.ObservableObject {}
                """)

                return [observationExtension, legacyExtension]
    }
    
    
    // MemberMacro: registrar 프로퍼티 주입
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return [
                // 1. Observation을 지원하는 환경인지 체크하는 조건부 컴파일 구문 추가
                """
                #if canImport(Observation)
                @ObservationIgnored
                private let _registrar: Any? = {
                    if #available(iOS 17.0, *) {
                        return ObservationRegistrar()
                    }
                    return nil
                }()

                @available(iOS 17.0, *)
                var registrar: ObservationRegistrar {
                    _registrar as! ObservationRegistrar
                }
                #endif
                """,
                
                // 2. Combine은 iOS 13부터이므로 비교적 안전하지만,
                // 하위 호환을 위해 명시적으로 유지
                "public let objectWillChange = Combine.ObservableObjectPublisher()"
            ]
    }
}
