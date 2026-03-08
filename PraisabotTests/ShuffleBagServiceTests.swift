import Foundation
import SwiftData
import Testing

@testable import Praisabot

@Test func pickNextReturnsUnsentMessage() throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: PraiseMessage.self, configurations: config)
    let context = ModelContext(container)

    let msg1 = PraiseMessage(text: "I love you")
    let msg2 = PraiseMessage(text: "You are amazing")
    context.insert(msg1)
    context.insert(msg2)
    try context.save()

    let service = ShuffleBagService()
    let picked = try service.pickNext(context: context)

    #expect(picked != nil)
    #expect(picked!.sentInCurrentCycle == true)
}

@Test func pickNextResetsWhenAllSent() throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: PraiseMessage.self, configurations: config)
    let context = ModelContext(container)

    let msg = PraiseMessage(text: "I love you")
    msg.sentInCurrentCycle = true
    context.insert(msg)
    try context.save()

    let service = ShuffleBagService()
    let picked = try service.pickNext(context: context)

    #expect(picked != nil)
    #expect(picked!.text == "I love you")
}

@Test func pickNextReturnsNilWhenNoMessages() throws {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: PraiseMessage.self, configurations: config)
    let context = ModelContext(container)

    let service = ShuffleBagService()
    let picked = try service.pickNext(context: context)

    #expect(picked == nil)
}
