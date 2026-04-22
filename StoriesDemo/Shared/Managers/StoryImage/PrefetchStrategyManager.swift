//
//  PrefetchStrategyManager.swift
//  StoriesDemo
//
//  Created by Yannick Juarez on 22/04/2026.
//

import SwiftUI
import Combine
import Foundation

@MainActor
final class PrefetchStrategyManager: ObservableObject {

    @Published private(set) var effectivePrefetchQueueSize: Int = 5

    private static let minPrefetchQueueSize = 4
    private static let maxPrefetchQueueSize = 12

    private var cancellables: Set<AnyCancellable> = []
    private var monitoringTask: Task<Void, Never>?

    @Published private var isConnectedToWifi = true
    @Published private var batteryLevel: Float = 50.0

    init() {
        setupBatteryMonitoring()
        startNetworkMonitoring()
        updateEffectiveQueueSize()
        setupObservation()
    }

    deinit {
        monitoringTask?.cancel()
    }

    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBatteryLevel()

        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryLevel()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .sink { [weak self] _ in
                self?.updateEffectiveQueueSize()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateEffectiveQueueSize()
            }
            .store(in: &cancellables)
    }

    private func updateBatteryLevel() {
        batteryLevel = UIDevice.current.batteryLevel
    }

    private func startNetworkMonitoring() {
        monitoringTask = Task {
            let monitor = NetworkMonitor.shared
            let updates = await monitor.stateUpdates()

            for await state in updates {
                if Task.isCancelled {
                    break
                }

                isConnectedToWifi = state.isWifi && state.isConnected
            }
        }
    }

    private func updateEffectiveQueueSize() {
        let processInfo = ProcessInfo.processInfo
        let min = Self.minPrefetchQueueSize
        let max = Self.maxPrefetchQueueSize


        var size = max


        if processInfo.isLowPowerModeEnabled
            || processInfo.thermalState == .critical
            || processInfo.thermalState == .serious {
            size = min
        }

        if processInfo.thermalState == .fair {
            size = Swift.max(min, size - 2)
        }

        if !isConnectedToWifi {
            size = Swift.max(min, size - 2)
        }

        if batteryLevel >= 0, batteryLevel < 0.2 {
            size = Swift.max(min, size - 1)
        }

        effectivePrefetchQueueSize = Swift.max(min, Swift.min(max, size))
    }
}

// MARK: - Observation Setup

extension PrefetchStrategyManager {
    func setupObservation() {
        Publishers.CombineLatest(
            $isConnectedToWifi,
            $batteryLevel
        )
        .sink { [weak self] _, _ in
            self?.updateEffectiveQueueSize()
        }
        .store(in: &cancellables)
    }
}
