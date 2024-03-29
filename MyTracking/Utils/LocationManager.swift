//
//  LocationManager.swift
//  SimpleSpeedometer
//
//  Created by TAEHYOUNG KIM on 10/18/23.
//

import UIKit
import CoreLocation
import Combine


class LocationManager: NSObject {
    deinit {
        print("LocationManager deinit")
    }
    
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    private var subscriptions = Set<AnyCancellable>()
    @Published var authorizationStatus: CLAuthorizationStatus?
    var showAlert: (() -> Void)?
    var trackingManager: TrackingManager?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        bind()
    }

    func bind() {
        SettingManager.shared.$activityType
            .sink { [weak self] type in
                guard let self else { return }
                self.update(type: type)
            }.store(in: &subscriptions)
    }

    func update(type: ActivicyType) {
        switch type {
        case .automobile, .bike:
            setup(accuracy: kCLLocationAccuracyBestForNavigation, type: .automotiveNavigation)
        case .train, .offroad_vehicle, .ferry:
            setup(accuracy: kCLLocationAccuracyBestForNavigation, type: .otherNavigation)
        case .airplane:
            setup(accuracy: kCLLocationAccuracyBestForNavigation, type: .airborne)
        case .running, .walking, .hiking, .cycling:
            setup(accuracy: kCLLocationAccuracyBest, type: .otherNavigation)
        }

        func setup(accuracy: CLLocationAccuracy, type: CLActivityType) {
            locationManager.desiredAccuracy = accuracy
//            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.activityType = type
        }
    }

    func start() {
        locationManager.startUpdatingLocation()
    }

    func stop() {
        locationManager.stopUpdatingLocation()
    }

    func requestAuthorization(authorized: (() -> Void)? = nil, denied: () -> Void) {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            denied()
        case .authorizedAlways, .authorizedWhenInUse:
            if let authorized {
                authorized()
            }
        default:
            break
        }
    }

    func reverseGeocodeLocation(_ coordinate: CLLocationCoordinate2D, maxAttempts: Int = 3, currentAttempt: Int = 0) async -> String {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemark = try await geocoder.reverseGeocodeLocation(location).first
            let array = [placemark?.locality, placemark?.subLocality].compactMap{ $0 }
            let result = array.joined(separator: " ")

            if result.trimmingCharacters(in: .whitespaces).count > 0 {
                return result
            } else {
                return "lat: \(coordinate.latitude), long: \(coordinate.longitude)"
            }
        } catch let error {
            if let error = error as NSError? {
                if error.code == CLError.network.rawValue && currentAttempt < maxAttempts {
                    return await self.reverseGeocodeLocation(coordinate, maxAttempts: maxAttempts, currentAttempt: currentAttempt + 1)
                } else {
                    return "lat: \(coordinate.latitude), long: \(coordinate.longitude)"
                }
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            trackingManager?.addLocationAndSpeed(location)
        }
        
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        requestAuthorization {
            DispatchQueue.main.async { [weak self] in
                self?.showAlert?()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("*****didFailWithError, \(error.localizedDescription)*****")
    }

    func locationManager(_ manager: CLLocationManager, didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint, error: Error) {
        print("*****didFailRangingFor, \(error.localizedDescription)*****")
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("*****monitoringDidFailFor, \(error.localizedDescription)*****")
    }

    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        print("*****didFinishDeferredUpdatesWithError, \(String(describing: error?.localizedDescription))*****")
    }

    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("*****DidPauseLocationUpdates*****")
        print("time: \(Date())")
    }

    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("*****DidResumeLocationUpdates*****")
        print("time: \(Date())")
    }


}
