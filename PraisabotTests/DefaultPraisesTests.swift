import Foundation
import Testing

@testable import Praisabot

@Test func defaultPraisesFileIsValidJSON() throws {
    let url = Bundle(for: PraiseMessage.self).url(
        forResource: "DefaultPraises", withExtension: "json"
    )
    // File is optional — only present in private builds
    guard let unwrappedURL = url else { return }
    let data = try Data(contentsOf: unwrappedURL)
    let praises = try JSONDecoder().decode([String].self, from: data)
    #expect(praises.count >= 1)
    #expect(praises.allSatisfy { !$0.isEmpty })
}
