import Foundation

/// Language scheduling only: blocking native await must not occupy Swift's
/// cooperative executor. Eight serial Dispatch lanes bound simultaneous waits
/// across the process; each host admits at most64 jobs including queued work.
/// No global Dispatch/OS policy is changed. Queues are initialized lazily on the
/// first async call and Dispatch owns its workers' process lifetime. Core still
/// owns request deadlines, matching and every ticket's native wait window.
enum RuntimeAskExecutor {
    private final class Lanes: @unchecked Sendable {
        let queues = (0..<8).map { DispatchQueue(label: "CoAkka.Runtime.ask.\($0)") }
        let lock = NSLock()
        var next = 0
        func enqueue(_ work: @escaping @Sendable () -> Void) {
            lock.lock()
            let queue = queues[next]
            next = (next + 1) % queues.count
            lock.unlock()
            queue.async(execute: work)
        }
    }
    private static let lanes = Lanes()
    static func enqueue(_ work: @escaping @Sendable () -> Void) { lanes.enqueue(work) }
}
