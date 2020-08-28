//
//  SkinFeaturesViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 26/08/2020.
//

import UIKit
import CoreData

private let reuseIdentifier = "Cell"

@available(iOS 14, *)
class SkinFeaturesViewController: UIViewController {
    
    private enum SidebarItemType: Int {
        case header, row, expandableRow
    }
    
    private enum SidebarSection: Int {
        case allEntries, entries, newFeature
    }
    
    private struct SidebarItem: Hashable, Identifiable {
            let id: UUID
            let type: SidebarItemType
            let title: String
            let subtitle: String?
            let image: UIImage?
        let skinFeature: SkinFeature?
        
        static func header(title: String, id: UUID = UUID()) -> Self {
            return SidebarItem(id: id, type: .header, title: title, subtitle: nil, image: nil, skinFeature: nil)
                }
        
        static func expandableRow(title: String, subtitle: String?, image: UIImage?, id: UUID = UUID()) -> Self {
            return SidebarItem(id: id, type: .expandableRow, title: title, subtitle: subtitle, image: image, skinFeature: nil)
                }
        
        static func row(title: String, subtitle: String?, image: UIImage?, id: UUID = UUID(), skinFeature: SkinFeature?) -> Self {
            return SidebarItem(id: id, type: .row, title: title, subtitle: subtitle, image: image, skinFeature: skinFeature)
                }
        }
    
    var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<SidebarSection,SidebarItem>!
    
    var managedObjectContext: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<SkinFeature>!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureCollectionView()
        configureDataSource()
        initialiseCoreData()
        applyInitialSnapshot()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        #if targetEnvironment(macCatalyst)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        #endif
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showEntries":
            guard let detailVC = (segue.destination as? DetailNavController)?.topViewController as? EntriesCollectionViewController else { return }
            detailVC.managedObjectContext = managedObjectContext
            if let sender = sender as? SkinFeature {
                detailVC.condition = sender
            }
        default:
            break
        }
    }
    

}

@available(iOS 14, *)
extension SkinFeaturesViewController: UICollectionViewDelegate {
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        switch indexPath.section {
        case SidebarSection.allEntries.rawValue:
            didSelectAllEntries()
        case SidebarSection.entries.rawValue:
            guard let feature = item.skinFeature else { break }
            didSelectSkinFeature(with: feature)
        case SidebarSection.newFeature.rawValue:
            didSelectNewFeature()
        default:
            didSelectAllEntries()
        }
    }
    
    private func didSelectAllEntries() {
        if let splitVC = splitViewController as? SplitViewController {
            print(splitVC.viewController(for: .secondary))
            if let detailVC = splitVC.viewController(for: .secondary) as? DetailNavController {
                if let entriesVC = detailVC.topViewController as? EntriesCollectionViewController {
                    entriesVC.showEntries(selectionType: .all)
                }
            }
        }
    }
    
    private func didSelectSkinFeature(with skinFeature: SkinFeature) {
        performSegue(withIdentifier: "showEntries", sender: skinFeature)
        /*if let splitVC = splitViewController as? SplitViewController {
            if let entriesVC = splitVC.viewController(for: .secondary) as? EntriesCollectionViewController {
                entriesVC.condition = skinFeature
                entriesVC.showEntries(selectionType: .all)
            }
        }*/
    }
    
    private func didSelectNewFeature() {
        
    }
    
    
    private func entriesViewController() -> EntriesCollectionViewController? {
        guard
            let splitViewController = self.splitViewController,
            let entriesVC = splitViewController.viewController(for: .secondary)
            else { return nil }
            
            return entriesVC as? EntriesCollectionViewController
        }
    
    
    
}

@available(iOS 14, *)
extension SkinFeaturesViewController {
    private func configureView() {
        navigationItem.title = "Skin Features"
        navigationController?.navigationBar.prefersLargeTitles = true
        //navigationController?.navigationBar.barTintColor = UIColor(named: "AccentColor")
    }

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
extension SkinFeaturesViewController {
    private func configureDataSource() {
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
                    (cell, indexPath, item) in
                    
                    var contentConfiguration = UIListContentConfiguration.sidebarHeader()
                    contentConfiguration.text = item.title
                    //contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .subheadline)
                    //contentConfiguration.textProperties.color = .secondaryLabel
                    
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
            
            var contentConfiguration = UIListContentConfiguration.sidebarCell()
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
                return collectionView.dequeueConfiguredReusableCell(using: expandableRowRegistration, for: indexPath, item: item)
            default:
                return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
            }
        }
    }
    
    private func allEntriesSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        let allEntries = SidebarItem.row(title: "All Entries", subtitle: nil, image: UIImage(systemName: "square.grid.3x2"), skinFeature: nil)
        
        snapshot.append([allEntries])
        return snapshot
    }
    
    private func featuresSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        for section in fetchedResultsController.sections! {
            let header = SidebarItem.header(title: section.name == "0" ? "Current" : "Archived")
            let image = UIImage(systemName: "photo")
            
            var items = [SidebarItem]()
            for object in fetchedResultsController.fetchedObjects! {
                items.append(.row(title: object.name!, subtitle: object.areaOfBody, image: image, skinFeature: object))
            }
            
            snapshot.append([header])
            snapshot.expand([header])
            snapshot.append(items, to: header)
        }
        return snapshot
    }
    
    private func newFeatureSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        let newFeature = SidebarItem.row(title: "New Skin Feature", subtitle: nil, image: UIImage(systemName: "plus"), skinFeature: nil)
        
        snapshot.append([newFeature])
        return snapshot
    }
    
    private func applyInitialSnapshot() {
        dataSource.apply(allEntriesSnapshot(), to: .allEntries, animatingDifferences: false)
        dataSource.apply(featuresSnapshot(), to: .entries, animatingDifferences: false)
        dataSource.apply(newFeatureSnapshot(), to: .newFeature, animatingDifferences: true)
    }
    
}
/*
// MARK: UICollectionViewDataSource
extension SkinFeaturesViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if let frc = fetchedResultsController {
            return frc.sections!.count
        }
        return 0
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        guard let sections = self.fetchedResultsController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
    
        return cell
    }
}*/

// MARK: Core Data
@available(iOS 14, *)
extension SkinFeaturesViewController {
    func initialiseCoreData() {
        let request = NSFetchRequest<SkinFeature>(entityName: "SkinFeature")
        let completeSort = NSSortDescriptor(key: "complete", ascending: true)
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [completeSort, nameSort]
        
        let undoMan = UndoManager.init()
        managedObjectContext.undoManager = undoMan
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "complete", cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    func updateCoreData() {
        do {
            try managedObjectContext!.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
}



// MARK: NSFetchedController
@available(iOS 14, *)
extension SkinFeaturesViewController: NSFetchedResultsControllerDelegate {
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.dataSource.apply(self.featuresSnapshot(), to: .entries)
    }
}

