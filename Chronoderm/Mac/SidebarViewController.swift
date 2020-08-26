//
//  SidebarViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 21/08/2020.
//

import UIKit

@available(iOS 14, *)
class SidebarViewController: UIViewController {
    
    private enum SidebarItemType: Int {
        case header, row, expandableRow
    }
    
    private enum SidebarSection: Int {
        case entries, favourites
    }
    
    private struct SidebarItem: Hashable, Identifiable {
            let id: UUID
            let type: SidebarItemType
            let title: String
            let subtitle: String?
            let image: UIImage?
        
        static func header(title: String, id: UUID = UUID()) -> Self {
                    return SidebarItem(id: id, type: .header, title: title, subtitle: nil, image: nil)
                }
        
        static func expandableRow(title: String, subtitle: String?, image: UIImage?, id: UUID = UUID()) -> Self {
                    return SidebarItem(id: id, type: .expandableRow, title: title, subtitle: subtitle, image: image)
                }
        
        static func row(title: String, subtitle: String?, image: UIImage?, id: UUID = UUID()) -> Self {
                    return SidebarItem(id: id, type: .row, title: title, subtitle: subtitle, image: image)
                }
        }
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<SidebarSection,SidebarItem>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureDataSource()
    }
    

}


@available(iOS 14, *)
extension SidebarViewController {

    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        view.addSubview(collectionView)
    }
    
    private func createLayout() -> UICollectionViewLayout {
            let layout = UICollectionViewCompositionalLayout() { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
                var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
                configuration.showsSeparators = false
                configuration.headerMode = .firstItemInSection
                let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
                return section
            }
            return layout
        }

}

@available(iOS 14, *)
extension SidebarViewController: UICollectionViewDelegate {
    
}

@available(iOS 14, *)
extension SidebarViewController {
    private func configureDataSource() {
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
                    (cell, indexPath, item) in
                    
                    var contentConfiguration = UIListContentConfiguration.sidebarHeader()
                    contentConfiguration.text = item.title
                    contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .subheadline)
                    contentConfiguration.textProperties.color = .secondaryLabel
                    
                    cell.contentConfiguration = contentConfiguration
                    cell.accessories = [.outlineDisclosure()]
                }
        
        let expandableRowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
            (cell, indexPath, item) in
            
            var contentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
            contentConfiguration.text = item.title
            contentConfiguration.secondaryText = item.subtitle
            contentConfiguration.image = item.image
            
            cell.contentConfiguration = contentConfiguration
            cell.accessories = [.outlineDisclosure()]
        }
        
        let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
            (cell, indexPath, item) in
            
            var contentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
            contentConfiguration.text = item.title
            contentConfiguration.secondaryText = item.subtitle
            contentConfiguration.image = item.image
            
            cell.contentConfiguration = contentConfiguration
        }
        
        dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell in
            
            switch item.type {
            case .header:
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            case .expandableRow:
                return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
            default:
                return collectionView.dequeueConfiguredReusableCell(using: expandableRowRegistration, for: indexPath, item: item)
            }
        }
    }
    
    
}

