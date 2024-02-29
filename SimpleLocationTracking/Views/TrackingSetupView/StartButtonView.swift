//
//  StartButtonView.swift
//  SimpleLocationTracking
//
//  Created by TAEHYOUNG KIM on 2/10/24.
//

import UIKit

import SnapKit

class StartButtonView: UIStackView {
    let imageView = UIImageView()
    let title = UILabel()
    let subTitle = UILabel()
    let titleAndSubTitleVStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Set Self(StackView)
        self.axis = .horizontal
        self.distribution = .fill
        self.alignment = .center
        self.spacing = 30
        self.isUserInteractionEnabled = false

        // Set Component
        setImageView()
        setTitleAndSubTitleVStackView()
        setTitle()
        setSubTitle()

        // Layout
        layout()
    }


    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImageView() {
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "road")
    }

    func setTitleAndSubTitleVStackView() {
        titleAndSubTitleVStackView.axis = .vertical
        titleAndSubTitleVStackView.distribution = .equalSpacing
        titleAndSubTitleVStackView.alignment = .leading
    }

    func setTitle() {
        title.font = .systemFont(ofSize: 50, weight: .medium)
        title.textColor = .white
        title.adjustsFontSizeToFitWidth = true
        title.text = "Start Tracking"
    }

    func setSubTitle() {
        subTitle.font = .systemFont(ofSize: 50)
        subTitle.textColor = .systemGray6
        subTitle.adjustsFontSizeToFitWidth = true
        subTitle.text = "Record Your Journey"
    }

    func layout() {
        [title, subTitle].forEach(titleAndSubTitleVStackView.addArrangedSubview(_:))
        [titleAndSubTitleVStackView, imageView].forEach(addArrangedSubview(_:))

        imageView.snp.makeConstraints { make in
            make.size.equalTo(self.snp.height).multipliedBy(0.8)
        }

        title.snp.makeConstraints { make in
            make.height.equalTo(self).multipliedBy(0.4)
        }

        subTitle.snp.makeConstraints { make in
            make.height.equalTo(self).multipliedBy(0.2)
        }
    }
}
