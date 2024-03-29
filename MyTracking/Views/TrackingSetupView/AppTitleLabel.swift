//
//  AppTitleLabel.swift
//  SimpleLocationTracking
//
//  Created by TAEHYOUNG KIM on 2/29/24.
//

import UIKit


class AppTitleLabel: UILabel {
    var title: String

    init(frame: CGRect, title: String) {
        self.title = title
        super.init(frame: frame)

        setTitle()
    }

    func setTitle() {
        self.numberOfLines = 1
        self.textAlignment = .left
        self.textColor = .label
        self.font = .roundedFont(size: 30, weight: .bold)
        self.setContentCompressionResistancePriority(.required, for: .vertical)
        self.setContentHuggingPriority(.required, for: .vertical)
        self.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
