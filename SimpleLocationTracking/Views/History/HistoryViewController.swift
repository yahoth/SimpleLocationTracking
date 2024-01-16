//
//  HistoryViewController.swift
//  SimpleLocationTracking
//
//  Created by TAEHYOUNG KIM on 12/28/23.
//

import UIKit
import Combine

import SnapKit

class HistoryViewController: UIViewController {
    deinit {
        print("HistoryViewController deinit")
    }

    var tableView: UITableView!
    var vm: HistoryViewModel!
    var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Tracking History"
        vm = HistoryViewModel()
        setTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        vm.addChangeListener(tableView)
    }


    func setTableView() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        setTableViewSeparator()
        tableView.register(HistoryCell.self, forCellReuseIdentifier: "HistoryCell")
        view.addSubview(tableView)
        setTableViewConstraints()

        func setTableViewSeparator() {
            tableView.separatorStyle = .singleLine
            tableView.separatorColor = .brown
            tableView.separatorInset = .init(top: 0, left: padding_body_view, bottom: 0, right: padding_body_view)
        }

        func setTableViewConstraints() {
            tableView.snp.makeConstraints { make in
                make.edges.equalTo(view)
            }
        }
    }
}

extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = vm.sortedGroups[indexPath.section].value[indexPath.row]
        let vc = TrackingResultViewController()
        vc.vm = TrackingResultViewModel(trackingData: item, viewType: .navigation)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension HistoryViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return vm.sortedGroups.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.sortedGroups[section].value.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var dateComponents = vm.sortedGroups[section].key
        dateComponents.timeZone = TimeZone.current
        let date = Calendar.current.date(from: dateComponents)!
        return date.formattedString(.yyyy_M)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as? HistoryCell else { return UITableViewCell() }
        let item = vm.sortedGroups[indexPath.section].value[indexPath.row]
        cell.configure(item: item)
        cell.selectionStyle = .none
        return cell
    }
}
