import Dispatch

class KQueue<T> {
    private let maxSize: Int
    private var items: [T]
    private let semaphore: DispatchSemaphore
    private let overflowDropFilter: ((T) -> Bool)?

    init(maxSize: Int, overflowDropFilter: ((T) -> Bool)? = nil) {
        self.maxSize = maxSize
        self.items = []
        self.items.reserveCapacity(maxSize)
        self.semaphore = DispatchSemaphore(value: 1)
        self.overflowDropFilter = overflowDropFilter
    }

    func capacity() -> Int {
        semaphore.wait()
        defer { semaphore.signal() }
        return items.count
    }

    func dequeue() -> T? {
        semaphore.wait()
        defer { semaphore.signal() }
        guard !items.isEmpty else {
            return nil
        }
        return items.removeFirst()
    }

    func dequeueAll() -> [T] {
        semaphore.wait()
        defer { semaphore.signal() }
        let result = items
        items.removeAll(keepingCapacity: true)
        return result
    }

    func peek() -> T? {
        semaphore.wait()
        defer { semaphore.signal() }
        return items.first
    }

    func peekAll() -> [T] {
        semaphore.wait()
        defer { semaphore.signal() }
        return items
    }

    func enqueue(item: T) {
        semaphore.wait()
        defer { semaphore.signal() }
        if items.count >= maxSize {
            if let overflowDropFilter = overflowDropFilter,
                let dropIndex = items.firstIndex(where: overflowDropFilter)
            {
                items.remove(at: dropIndex)
            } else {
                items.removeFirst()
            }
        }
        items.append(item)
    }
}
