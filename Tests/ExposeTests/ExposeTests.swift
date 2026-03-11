import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(ExposeMacros)
import ExposeMacros

private let testMacros: [String: Macro.Type] = [
    "Exposable": ExposableMacro.self,
]
#endif

final class ExposeTests: XCTestCase {
    func testExposableMacroExpansion() throws {
        #if canImport(ExposeMacros)
        assertMacroExpansion(
            """
            @Exposable
            final class AuctionViewModel {
            }
            """,
            expandedSource: """
                final class AuctionViewModel {

                    @ObservationIgnored
                    public let registrar = ObservationRegistrar()
                }

                extension AuctionViewModel: ExposableObject {
                }
                """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
