//
//  HistoryViewModel.swift
//  SimpleLocationTracking
//
//  Created by TAEHYOUNG KIM on 12/30/23.
//

import UIKit

import RealmSwift

class HistoryViewModel {

    let realmManager = RealmManager.shared
    let settingManager = SettingManager.shared

    deinit {
        print("HistoryViewModel deinit")
    }

    var trackingDatas: Results<TrackingData> {
        realmManager.read()
    }

    var unitOfSpeed: UnitOfSpeed {
        settingManager.unit
    }

    func addChangeListener(_  handler: @escaping (RealmCollectionChange<Results<TrackingData>>) -> ()) {
        realmManager.notificationToken =
        trackingDatas.observe { changes in handler(changes) }
    }

    var dic: [String: [TrackingData]] {
        Dictionary(grouping: trackingDatas, by:  { $0.monthlyIdentifier })
    }

    var keys: [String] {
        // given: "2024-5", "2024-4", "2024-6"
        // sorted: "2024-4", "2024-5", "2024-6"
        dic.keys.sorted { key1, key2 in
            let date1 = key1.components(separatedBy: "-")
            let date2 = key2.components(separatedBy: "-")

            if let year1 = Int(date1[0]), let year2 = Int(date2[0]), let month1 = Int(date1[1]), let month2 = Int(date2[1]) {
                if year1 == year2 {
                    return month1 < month2
                } else {
                    return year1 < year2
                }
            }
            return key1 < key2
        }
    }

    func selectedItem(at indexPath: IndexPath) -> TrackingData? {
        let key = keys.reversed()[indexPath.section]
        guard let items = dic[key], items.indices.contains(indexPath.item) else { return nil }
        return items[indexPath.item]
    }

    var languageCode: String {
        if #available(iOS 16, *) {
            return Locale.current.language.languageCode?.identifier ?? "en_US"
        } else {
            return Locale.current.languageCode ?? "en_US"
        }
    }

    func formattedHeader(_ date: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        guard let date = dateFormatter.date(from: date) else {
            print("hello")
            return date
        }
        dateFormatter.locale = Locale(identifier: languageCode)

        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MMM")
        return dateFormatter.string(from: date)
    }
}
