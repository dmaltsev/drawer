import Foundation

struct WeakCollection<T> {
    private class Box {
        weak var object: AnyObject?

        init(_ object: AnyObject) {
            self.object = object
        }
    }

    private var _elems: ContiguousArray<Box>

    var count: Int {
        return _elems.count
    }

    init() {
        _elems = []
    }

    func forEach(_ block: (T) -> Void) {
        for elem in _elems {
            if let obj = elem.object as? T {
                block(obj)
            }
        }
    }

    mutating func insert(_ elem: T) {
        removeNilElems()
        if index(of: elem) == nil {
            _elems.append(Box(elem as AnyObject))
        }
    }

    mutating func remove(_ elem: T) {
        removeNilElems()
        if let index = index(of: elem) {
            _elems.remove(at: index)
        }
    }

    mutating func isEmpty() -> Bool {
        removeNilElems()
        return _elems.isEmpty
    }

    private mutating func removeNilElems() {
        _elems = _elems.filter { $0.object != nil }
    }

    private func index(of elem: T) -> Int? {
        return _elems.firstIndex(where: { $0.object === elem as AnyObject })
    }
}

