//
//  TrackingViewModel.swift
//  SimpleLocationTracking
//
//  Created by TAEHYOUNG KIM on 11/29/23.
//

import Foundation
import Combine
import CoreLocation

import FloatingPanel
import RealmSwift

final class TrackingViewModel {

    deinit {
        print("TrackingViewModel deinit")
        locationManager.locationInfo = nil
    }

    let locationManager = LocationManager.shared
    private let settingManager = SettingManager.shared
    private let stopwatch = Stopwatch()
    private var subscriptions = Set<AnyCancellable>()
    private var startDate: Date?
    var endDate: Date?

    var speedInfos: [SpeedInfo] {
        [
            SpeedInfo(value: locationManager.locationInfo?.averageSpeed ?? 0, unit: unitOfSpeed?.displayedSpeedUnit, title: "Average Speed"),
            SpeedInfo(value: locationManager.locationInfo?.topSpeed ?? 0, unit: unitOfSpeed?.displayedSpeedUnit, title: "Top Speed"),
            SpeedInfo(value: locationManager.locationInfo?.distance ?? 0, unit: unitOfSpeed?.correspondingDistanceUnit, title: "Distance"),
            SpeedInfo(value: locationManager.locationInfo?.currentAltitude ?? 0, unit: unitOfSpeed?.correspondingAltitudeUnit, title: "Current Altitude"),
        ]
    }

    @MainActor
    func createTrackingResult() async -> TrackingData {

        let speedInfos = [
            SpeedInfo(value: locationManager.locationInfo?.distance ?? 0, unit: unitOfSpeed?.correspondingDistanceUnit, title: "Distance"),
            SpeedInfo(value: endDate?.timeIntervalSince(startDate ?? Date()) ?? totalElapsedTime, unit: nil, title: "Time"),
            SpeedInfo(value: locationManager.locationInfo?.averageSpeed ?? 0, unit: unitOfSpeed?.displayedSpeedUnit, title: "Average Speed"),
            SpeedInfo(value: locationManager.locationInfo?.topSpeed ?? 0, unit: unitOfSpeed?.displayedSpeedUnit, title: "Top Speed"),
            SpeedInfo(value: locationManager.locationInfo?.altitude ?? 0, unit: unitOfSpeed?.correspondingAltitudeUnit, title: "Altitude"),
        ]

        let locationDatas = locationManager.locationInfo?.timedLocationDatas ?? []

        let startLocation = await locationManager.reverseGeocodeLocation(locationDatas.first?.coordinate ?? CLLocationCoordinate2D())

        let endLocation = await locationManager.reverseGeocodeLocation(locationDatas.last?.coordinate ?? CLLocationCoordinate2D())
        let speeds = locationManager.locationInfo?.speeds ?? []
        let pathInfo = PathInfo(locationDatas: locationDatas, speeds: speeds)

        let trackingData = TrackingData(speedInfos: speedInfos.toRealmList(), pathInfo: pathInfo, startDate: startDate ?? Date(), endDate: endDate ?? Date(), startLocation: startLocation, endLocation: endLocation, activityType: settingManager.activityType)

        DispatchQueue.main.async {
            RealmManager.shared.create(object: trackingData)
        }

        return trackingData
    }


    @Published var state: FloatingPanelState
    weak var fpc: FloatingPanelController?

    init(fpc: FloatingPanelController) {
        self.state = fpc.state
        self.fpc = fpc
        locationManager.locationInfo = TrackingManager()
        bind()
    }

    var convertedSpeed: Double {
        locationManager.locationInfo?.speed.speedToSelectedUnit(unitOfSpeed ?? .kmh) ?? 0
    }

    @Published var isPaused: Bool = true
    @Published var isStopped: Bool = false
    @Published var unitOfSpeed: UnitOfSpeed?
    @Published var totalElapsedTime: Double = 0

    var points: [CLLocationCoordinate2D]? {
        locationManager.locationInfo?.points
    }

    private func bind() {
        stopwatch.$count
            .sink { [weak self] count in
                self?.totalElapsedTime = count
            }.store(in: &subscriptions)

        settingManager.$unit
            .sink { [weak self] unit in
                self?.unitOfSpeed = unit
            }.store(in: &subscriptions)
    }


    func updateUnit(_ unit: UnitOfSpeed) {
        settingManager.updateUnit(unit)
    }

    func startAndPause() {
        if isPaused {
            locationManager.start()
            stopwatch.start()
            isPaused = false
            isStopped = false
            if startDate == nil {
                startDate = Date()
            }
        } else {
            locationManager.stop()
            stopwatch.pause()
            isPaused = true
        }
    }

    func stop() {
        locationManager.stop()
        stopwatch.pause()
        isPaused = true
        isStopped = true
    }

//   func calculateDistance() -> CLLocationDistance {
//        let totalDistance = averageSpeed * Double(stopwatch.count) / 3600
//       print("distance: \(distance)")
//       print("calculat: \(totalDistance)")
//       return totalDistance
//    }
}
