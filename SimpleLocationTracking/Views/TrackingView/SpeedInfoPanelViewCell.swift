//
//  SpeedInfoPanelViewCell.swift
//  SimpleLocationTracking
//
//  Created by TAEHYOUNG KIM on 12/15/23.
//

import UIKit

class SpeedInfoPanelViewCell: BaseSpeedInfoCell {
    deinit {
        print("SpeedInfoPanelViewCell deinit")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setLabels()
        setContentView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLabels() {
        titleLabel.font = .systemFont(ofSize: 20)
        titleLabel.textColor = .white

        valueLabel.font = .systemFont(ofSize: 28, weight: .bold)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .right

        unitLabel.font = .systemFont(ofSize: 20)
        unitLabel.textColor = .white
    }

    func setContentView() {
        contentView.layer.cornerRadius = 12
        contentView.backgroundColor = .accent
    }

    func configure(_ info: SpeedInfo) {
        titleLabel.text = info.title
        if info.title != "Time" {
            valueLabel.text = String(format: "%.1f", info.value)
        } else {
            valueLabel.text = info.value.resultTime
        }
        unitLabel.text = info.unit
    }

}
