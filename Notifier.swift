import Foundation

class Notifier<Listener> {
    var hasNoListeners: Bool {
        return listeners.isEmpty()
    }

    private var listeners: WeakCollection<Listener>

    var count: Int {
        return listeners.count
    }

    init() {
        listeners = WeakCollection<Listener>()
    }

    func subscribe(_ listener: Listener) {
        listeners.insert(listener)
    }

    func unsubscribe(_ listener: Listener) {
        listeners.remove(listener)
    }

    func forEach(_ block: (Listener) -> Void) {
        listeners.forEach(block)
    }
}
