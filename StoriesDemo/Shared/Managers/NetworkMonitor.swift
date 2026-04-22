//
//  NetworkMonitor.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 22/04/2026.
//

import Network
import Foundation

actor NetworkMonitor {
    struct State: Sendable, Equatable {
        let isWifi: Bool
        let isConnected: Bool
    }

    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.storieselmo.network-monitor")

    private var _isWifi: Bool = true
    private var _isConnected: Bool = true
    private var subscribers: [UUID: AsyncStream<State>.Continuation] = [:]

    var isWifi: Bool {
        _isWifi
    }

    var isConnected: Bool {
        _isConnected
    }

    var currentState: State {
        State(isWifi: _isWifi, isConnected: _isConnected)
    }

    func stateUpdates() -> AsyncStream<State> {
        let subscriptionID = UUID()

        return AsyncStream { [weak self] continuation in
            Task {
                guard let self else {
                    continuation.finish()
                    return
                }

                await self.addSubscriber(continuation, id: subscriptionID)

                continuation.onTermination = { [weak self] _ in
                    Task {
                        await self?.removeSubscriber(subscriptionID)
                    }
                }
            }
        }
    }

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.updatePath(path)
            }
        }
        monitor.start(queue: queue)
    }

    private func updatePath(_ path: NWPath) {
        _isConnected = path.status == .satisfied
        _isWifi = path.usesInterfaceType(.wifi)

        let state = currentState
        for continuation in subscribers.values {
            continuation.yield(state)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers.removeValue(forKey: id)
    }

    private func addSubscriber(_ continuation: AsyncStream<State>.Continuation, id: UUID) {
        subscribers[id] = continuation
        continuation.yield(currentState)
    }

    deinit {
        monitor.cancel()
    }
}
