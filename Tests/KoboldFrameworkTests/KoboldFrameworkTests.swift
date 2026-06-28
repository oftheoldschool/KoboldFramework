import XCTest
@testable import KoboldFramework

final class KoboldFrameworkTests: XCTestCase {
    func testQueueIsFifoAndEvictsOldestOnOverflow() {
        let queue = KQueue<Int>(maxSize: 3)
        queue.enqueue(item: 1)
        queue.enqueue(item: 2)
        queue.enqueue(item: 3)

        XCTAssertEqual(queue.capacity(), 3)
        XCTAssertEqual(queue.peek(), 1, "peek returns the oldest item")

        // Exceeding maxSize with no overflow filter drops the oldest item.
        queue.enqueue(item: 4)
        XCTAssertEqual(queue.capacity(), 3)

        XCTAssertEqual(queue.dequeueAll(), [2, 3, 4], "FIFO order preserved after eviction")
        XCTAssertNil(queue.dequeue(), "queue is empty after draining")
    }
}
