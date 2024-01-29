//
//  HistoryViewController.swift
//  SimpleLocationTracking
//
//  Created by TAEHYOUNG KIM on 12/28/23.
//

import UIKit
import Combine

import SnapKit
import RealmSwift

class HistoryViewController: UIViewController {

    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    var collectionView: UICollectionView!
    var vm: HistoryViewModel!
    var subscriptions = Set<AnyCancellable>()
    typealias Item = TrackingData
    struct Section: Hashable {
        let keys: String
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        vm = HistoryViewModel()
        createCollectionView()
        createDatasource()
        updateCollectionView()
    }

    func createCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout())
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        collectionView.register(HistoryCell.self, forCellWithReuseIdentifier: "HistoryCell")
        collectionView.register(HistoryHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: HistoryHeaderView.identifier)
        collectionView.delegate = self
    }

    func createDatasource() {
        datasource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HistoryCell", for: indexPath) as? HistoryCell else { return nil }
            cell.configure(item: item, unit: self?.vm.unitOfSpeed ?? .kmh)
            return cell
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration
        <UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) {
            (supplementaryView, elementKind, indexPath) in
            let section = self.datasource.snapshot().sectionIdentifiers[indexPath.section]
            var content = supplementaryView.defaultContentConfiguration()
            content.text = section.keys
//            content.directionalLayoutMargins = .init(top: 20, leading: 20, bottom: 20, trailing: 20)
            supplementaryView.contentConfiguration = content
        }

        datasource.supplementaryViewProvider = { (_, _, index) in
            return self.collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: index)
        }

        let snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        datasource.apply(snapshot)
    }

    func updateCollectionView() {
        vm.addChangeListener { [weak self] changes in
            guard let self else { return }
            switch changes {
            case .initial, .update:
                self.applySnapshot()
            case .error(let error):
                print("collection view update error: \(error)")
            }
        }
    }

    func applySnapshot() {
        var snapshot = datasource.snapshot()
        snapshot.deleteAllItems()
        let sections = vm.keys.map { Section(keys: $0) }
        snapshot.appendSections(sections.reversed())
        sections.forEach { snapshot.appendItems(vm.dic[$0.keys] ?? [], toSection: $0) }
        datasource.apply(snapshot)
    }

    func delete(item: TrackingData) {
        var snapshot = datasource.snapshot()
        let section = snapshot.sectionIdentifier(containingItem: item)!
        snapshot.deleteItems([item])

        if snapshot.itemIdentifiers(inSection: section).isEmpty {
            snapshot.deleteSections([section])
        }

        datasource.apply(snapshot) { [weak self] in
            self?.vm.realmManager.deleteObjectsOf(type: item)
        }
    }

    func layout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            var listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
            listConfiguration.showsSeparators = false
            listConfiguration.backgroundColor = .clear
            listConfiguration.trailingSwipeActionsConfigurationProvider = self?.makeSwipeActions
//            listConfiguration.headerMode = sectionIndex == 0 ? .supplementary : .none
            let section = NSCollectionLayoutSection.list(using: listConfiguration,
                                                         layoutEnvironment: layoutEnvironment)
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            section.boundarySupplementaryItems = [sectionHeader]
            section.interGroupSpacing = padding_body_body
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: padding_body_view, bottom: padding_body_view, trailing: padding_body_view)
            return section
        }

        return layout

    }

    private func makeSwipeActions(for indexPath: IndexPath?) -> UISwipeActionsConfiguration? {
        guard let indexPath, let item = datasource.itemIdentifier(for: indexPath) else { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.delete(item: item)
            completion(false)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    private func makeDeleteContextualAction(forRowAt indexPath: IndexPath) -> UIAction {
        return UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            guard let self, let item = self.datasource.itemIdentifier(for: indexPath) else { return }
            self.delete(item: item)
        }
    }
}

extension HistoryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = vm.trackingDatas[indexPath.section]
        let vc = TrackingResultViewController()
        vc.vm = TrackingResultViewModel(trackingData: item, viewType: .navigation)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let deleteAction = self.makeDeleteContextualAction(forRowAt: indexPath)
            return UIMenu(title: "", children: [deleteAction])
        }
        return configuration
    }
}
