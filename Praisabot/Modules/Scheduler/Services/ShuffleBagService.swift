import Foundation
import SwiftData

struct ShuffleBagService: Sendable {
    func pickNext(context: ModelContext) throws -> PraiseMessage? {
        var descriptor = FetchDescriptor<PraiseMessage>(
            predicate: #Predicate { !$0.sentInCurrentCycle }
        )

        var unsent = try context.fetch(descriptor)

        if unsent.isEmpty {
            // Reset cycle
            let allDescriptor = FetchDescriptor<PraiseMessage>()
            let all = try context.fetch(allDescriptor)
            guard !all.isEmpty else { return nil }
            for message in all {
                message.sentInCurrentCycle = false
            }
            try context.save()
            unsent = try context.fetch(descriptor)
        }

        guard let picked = unsent.randomElement() else { return nil }
        picked.sentInCurrentCycle = true
        try context.save()
        return picked
    }
}
