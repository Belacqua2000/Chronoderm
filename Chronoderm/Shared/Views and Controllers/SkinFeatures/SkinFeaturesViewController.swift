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
        case entries, addEntry
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
    
    var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<SidebarSection,SidebarItem>!
    
    var managedObjectContext: NSManagedObjectContext!
    var fetchedResultsController: NSFetchedResultsController<SkinFeature>!

    override func viewDidLoad() {
        super.viewDidLoad()
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}

@available(iOS 14, *)
extension SkinFeaturesViewController {
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
}

@available(iOS 14, *)
extension SkinFeaturesViewController {

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
extension SkinFeaturesViewController: UICollectionViewDelegate {
    
}

@available(iOS 14, *)
extension SkinFeaturesViewController {
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
                return collectionView.dequeueConfiguredReusableCell(using: expandableRowRegistration, for: indexPath, item: item)
            default:
                return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
            }
        }
    }
    
    private func featuresSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        let header = SidebarItem.header(title: "Skin Features")
        let image = UIImage(systemName: "plus")
        
        var items = [SidebarItem]()
        for object in fetchedResultsController.fetchedObjects! {
            items.append(.row(title: object.name!, subtitle: object.areaOfBody, image: image))
        }
        
        snapshot.append([header])
        snapshot.expand([header])
        snapshot.append(items, to: header)
        return snapshot
    }
    
    private func applyInitialSnapshot() {
        dataSource.apply(featuresSnapshot(), to: .entries, animatingDifferences: false)
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
    /*
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            skinFeaturesCollectionView.insertSections(IndexSet(integer: sectionIndex))
        case .delete:
            skinFeaturesCollectionView.deleteSections(IndexSet(integer: sectionIndex))
        case .move:
            break
        case .update:
            break
        @unknown default:
            break
        }
    }
     
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.skinFeaturesCollectionView.performBatchUpdates({
                self.skinFeaturesCollectionView.insertItems(at: [newIndexPath!])
                self.skinFeaturesCollectionView.reloadSections(IndexSet.init(integer: 0))
            },completion: {_ in})
        case .delete:
            self.skinFeaturesCollectionView.deleteItems(at: [indexPath!])
            self.skinFeaturesCollectionView.reloadSections(IndexSet.init(integer: 0))
        case .update:
            skinFeaturesCollectionView.reloadItems(at: [indexPath!])
        case .move:
            self.skinFeaturesCollectionView.performBatchUpdates({
                self.skinFeaturesCollectionView.moveItem(at: indexPath!, to: newIndexPath!)
                self.skinFeaturesCollectionView.reloadSections(IndexSet.init(integer: 0))
            },completion: {_ in})
        @unknown default:
            break
        }
    }
     
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        skinFeaturesCollectionView.performBatchUpdates(nil, completion: nil)
    }
 */
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.dataSource.apply(self.featuresSnapshot(), to: .entries)
    }
}

