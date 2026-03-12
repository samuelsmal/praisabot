import Foundation
import Testing

@testable import Praisabot

@Test func defaultPraisesFileIsValidJSON() throws {
    let url = Bundle(for: PraiseMessage.self).url(
        forResource: "DefaultPraises", withExtension: "json"
    )
    let unwrappedURL = try #require(url, "DefaultPraises.json not found in bundle")
    let data = try Data(contentsOf: unwrappedURL)
    let praises = try JSONDecoder().decode([String].self, from: data)
    #expect(praises.count >= 30)
    #expect(praises.allSatisfy { !$0.isEmpty })
}
