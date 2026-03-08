import Foundation
import Testing

@testable import Praisabot

@Test func praiseMessageDefaultValues() {
    let msg = PraiseMessage(text: "You are wonderful")

    #expect(msg.text == "You are wonderful")
    #expect(msg.sentInCurrentCycle == false)
    #expect(msg.createdAt <= Date.now)
}
