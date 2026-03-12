import Foundation
import SwiftData

struct ShuffleBagService: Sendable {
    func pickNext(context: ModelContext) throws -> PraiseMessage? {
        let descriptor = FetchDescriptor<PraiseMessage>(
            predicate: #Predicate { !$0.sentInCurrentCycle }
        )

        var unsent = try context.fetch(descriptor)

        if unsent.isEmpty {
            let allDescriptor = FetchDescriptor<PraiseMessage>()
            let all = try context.fetch(allDescriptor)
            guard !all.isEmpty else { return nil }
            for message in all {
                message.sentInCurrentCycle = false
            }
            try context.save()
            unsent = try context.fetch(descriptor)
        }

        return unsent.randomElement()
    }

    func markSent(_ message: PraiseMessage, context: ModelContext) throws {
        message.sentInCurrentCycle = true
        try context.save()
    }
}
