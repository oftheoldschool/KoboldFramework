import Dispatch
import KoboldLogging

class KQueue<T> {
    private var first: Int
    private var next: Int
    private let maxSize: Int
    private var items: ContiguousArray<T?>
    private let semaphore: DispatchSemaphore

    init(maxSize: Int, defaultValue: T? = nil) {
        self.maxSize = maxSize
        self.items = ContiguousArray.init(repeating: defaultValue, count: maxSize)
        self.first = 0
        self.next = 0
        self.semaphore = DispatchSemaphore(value: 1)
    }

    func capacity() -> Int {
        var capacity = 0
        if next == first && items[first] != nil {
            capacity = maxSize
        } else if next >= first {
            capacity = next - first
        } else {
            capacity = next + maxSize - first
        }
        return capacity
    }

    func dequeue() -> T? {
        semaphore.wait()
        let item: T? = items[first]
        if item != nil {
            items[first] = nil
            first += 1
            if first == maxSize {
                first = 0
            }
        }
        semaphore.signal()
        return item
    }

    func dequeueAll() -> [T] {
        semaphore.wait()
        var events: [T?] = []
        if first < next {
            events = Array(items[first..<next])
        } else if items[first] != nil {
            events = Array(items[first..<maxSize] + items[..<next])
        }
        items = ContiguousArray.init(repeating: nil, count: maxSize)
        first = 0
        next = 0
        semaphore.signal()
        return events.compactMap { $0 }
    }

    func peek() -> T? {
        semaphore.wait()
        let item: T? = items[first]
        semaphore.signal()
        return item
    }

    func peekAll() -> [T] {
        semaphore.wait()
        var events: [T?] = []
        if first < next {
            events = Array(items[first..<next])
        } else if items[first] != nil {
            events = Array(items[first..<maxSize] + items[..<next])
        }
        semaphore.signal()
        return events.compactMap { $0 }
    }

    func enqueue(item: T) {
        semaphore.wait()
        if first == next && items[first] != nil {
//            kwarn("warning: overwriting item in queue")
            first += 1
            if first == maxSize {
                first = 0
            }
        }
        items[next] = item
        next += 1
        if next == maxSize {
            next = 0
        }
        semaphore.signal()
    }
}
