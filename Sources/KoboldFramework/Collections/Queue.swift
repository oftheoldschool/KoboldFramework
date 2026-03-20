import Dispatch

class KQueue<T> {
    private let maxSize: Int
    private var items: ContiguousArray<T?>
    private var first: Int
    private var count: Int
    private let semaphore: DispatchSemaphore
    private let overflowDropFilter: ((T) -> Bool)?

    init(maxSize: Int, overflowDropFilter: ((T) -> Bool)? = nil) {
        precondition(maxSize > 0, "KQueue maxSize must be greater than zero")
        self.maxSize = maxSize
        self.items = ContiguousArray(repeating: nil, count: maxSize)
        self.first = 0
        self.count = 0
        self.semaphore = DispatchSemaphore(value: 1)
        self.overflowDropFilter = overflowDropFilter
    }

    func capacity() -> Int {
        semaphore.wait()
        defer { semaphore.signal() }
        return count
    }

    func dequeue() -> T? {
        semaphore.wait()
        defer { semaphore.signal() }
        guard count > 0 else {
            return nil
        }

        let item = items[first]
        items[first] = nil
        first = index(offsetFromFirst: 1)
        count -= 1
        return item
    }

    func dequeueAll() -> [T] {
        semaphore.wait()
        defer { semaphore.signal() }
        guard count > 0 else {
            return []
        }

        var result: [T] = []
        result.reserveCapacity(count)

        for offset in 0..<count {
            let idx = index(offsetFromFirst: offset)
            if let item = items[idx] {
                result.append(item)
            }
            items[idx] = nil
        }

        first = 0
        count = 0
        return result
    }

    func peek() -> T? {
        semaphore.wait()
        defer { semaphore.signal() }
        guard count > 0 else {
            return nil
        }
        return items[first]
    }

    func peekAll() -> [T] {
        semaphore.wait()
        defer { semaphore.signal() }
        guard count > 0 else {
            return []
        }

        var result: [T] = []
        result.reserveCapacity(count)
        for offset in 0..<count {
            let idx = index(offsetFromFirst: offset)
            if let item = items[idx] {
                result.append(item)
            }
        }
        return result
    }

    func enqueue(item: T) {
        semaphore.wait()
        defer { semaphore.signal() }

        if count >= maxSize {
            if let overflowDropFilter = overflowDropFilter {
                // Keep hot-path overflow O(1): drop incoming non-critical items immediately.
                if overflowDropFilter(item) {
                    return
                }

                if let dropOffset = firstOffsetMatching(overflowDropFilter) {
                    removeAtOffset(dropOffset)
                } else {
                    removeFirst()
                }
            } else {
                removeFirst()
            }
        }

        let insertIndex = index(offsetFromFirst: count)
        items[insertIndex] = item
        count += 1
    }

    private func index(offsetFromFirst offset: Int) -> Int {
        let raw = first + offset
        if raw >= maxSize {
            return raw % maxSize
        }
        return raw
    }

    private func removeFirst() {
        guard count > 0 else {
            return
        }
        items[first] = nil
        first = index(offsetFromFirst: 1)
        count -= 1
    }

    private func firstOffsetMatching(_ predicate: (T) -> Bool) -> Int? {
        guard count > 0 else {
            return nil
        }
        for offset in 0..<count {
            let idx = index(offsetFromFirst: offset)
            if let item = items[idx], predicate(item) {
                return offset
            }
        }
        return nil
    }

    private func removeAtOffset(_ offset: Int) {
        guard offset >= 0, offset < count else {
            return
        }
        if offset == 0 {
            removeFirst()
            return
        }

        var currentOffset = offset
        while currentOffset < count - 1 {
            let fromIndex = index(offsetFromFirst: currentOffset + 1)
            let toIndex = index(offsetFromFirst: currentOffset)
            items[toIndex] = items[fromIndex]
            currentOffset += 1
        }

        let lastIndex = index(offsetFromFirst: count - 1)
        items[lastIndex] = nil
        count -= 1
    }
}
