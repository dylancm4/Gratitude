//
//  TimelineViewController.swift
//  Gratitude
//
//  Created by Dylan Miller on 3/25/17.
//  Copyright © 2017 Dylan Miller. All rights reserved.
//

import UIKit

class TimelineViewController: ViewControllerBase {
    
    @IBOutlet weak var tableView: UITableView!
    
    var sections = [TimelineSection]()
    
    var newEntryObserver: NSObjectProtocol?
    var replaceEntryObserver: NSObjectProtocol?
    var deleteEntryObserver: NSObjectProtocol?
    
    deinit {
        
        // Remove all of this object's observers. For block-based observers,
        // we need a separate removeObserver(observer:) call for each observer.
        if let newEntryObserver = newEntryObserver {
            
            NotificationCenter.default.removeObserver(newEntryObserver)
        }
        if let replaceEntryObserver = replaceEntryObserver {
            
            NotificationCenter.default.removeObserver(replaceEntryObserver)
        }
        if let deleteEntryObserver = deleteEntryObserver {
            
            NotificationCenter.default.removeObserver(deleteEntryObserver)
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set up the navigation bar.
        if let navigationController = navigationController {
            
            // Set the navigation bar background color.
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.barTintColor = Constants.Color.darkTeal
            
            // Set the navigation bar text and icon color.
            navigationController.navigationBar.tintColor = Constants.Color.offWhite
            navigationController.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : Constants.Color.lightTeal]
            
            // Set the navigation bar title.
            navigationItem.title = nil
            self.navigationItem.titleView = UIImageView(image: UIImage(named: Constants.ImageName.gratitudeNavBar))
            
            // Add the settings button.
            let settingsButton = UIBarButtonItem(
                image: UIImage(named: Constants.ImageName.settingsButton),
                style: .plain,
                target: self,
                action: #selector(TimelineViewController.onSettingsButton))
            navigationItem.leftBarButtonItem  = settingsButton
            
            // Add the compose button.
            let composeButton = UIBarButtonItem(
                image: UIImage(named: Constants.ImageName.composeButton),
                style: .plain,
                target: self,
                action: #selector(TimelineViewController.onComposeButton))
            navigationItem.rightBarButtonItem  = composeButton
        }
        
        // Set up the tableView.
        tableView.estimatedSectionHeaderHeight = 30
        // Changed sectionHeaderHeight from UITableViewAutomaticDimension to 30
        // to prevent exception: "'NSInternalInconsistencyException', reason:
        // 'Missing cell for newly visible row X'"
        tableView.sectionHeaderHeight = 30
        tableView.estimatedRowHeight = 438
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(
            UINib(nibName: Constants.ClassName.timelineTableViewCellXib, bundle: nil),
            forCellReuseIdentifier: Constants.CellReuseIdentifier.timelineCell)
        
        // When an entry is created, add it to the table.
        newEntryObserver = NotificationCenter.default.addObserver(
            forName: Constants.NotificationName.newEntry,
            object: nil,
            queue: OperationQueue.main)
        { [weak self] (notification: Notification) in
            
            if let _self = self,
                let entry = notification.object as? Entry {
                
                let sectionWasAdded = _self.addNewEntry(entry)
                
                DispatchQueue.main.async {
                    
                    if sectionWasAdded {
                        
                        // When a section is added, reload the entire table.
                        _self.tableView.reloadData()
                    }
                    else {
                        
                        // When the entry was added to the first section,
                        // just reload the first section.
                        _self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
                    }
                    
                    // Scroll to top when an entry is created.
                    _self.tableView.setContentOffset(CGPoint(x: 0, y: 0 - _self.tableView.contentInset.top), animated: true)
                }
            }
        }
        
        // When an entry is replaced, update it in the table.
        replaceEntryObserver = NotificationCenter.default.addObserver(
            forName: Constants.NotificationName.replaceEntry,
            object: nil,
            queue: OperationQueue.main)
        { [weak self] (notification: Notification) in
            
            if let _self = self,
                let replaceEntryObject = notification.object as? ReplaceEntryNotificationObject,
                let entryReplacedInSectionIndex = _self.replaceEntry(withId: replaceEntryObject.entryId, replacementEntry: replaceEntryObject.replacementEntry) {
                
                DispatchQueue.main.async {
                    
                    // Reload the section containing the replaced entry.
                    // Save/restore the contentOffset, since when this is not
                    // done the table sometimes scrolls away from an updated
                    // entry. Saving/restoring does not completely fix this,
                    // but it helps.
                    let contentOffset = _self.tableView.contentOffset
                    if replaceEntryObject.useFadeAnimation {
                        
                        _self.tableView.reloadSections(IndexSet(integer: entryReplacedInSectionIndex), with: .fade)
                    }
                    else {
                        
                        // Reload the updated section without animating, since a
                        // replacement when the timeline is visible will often be
                        // of an updated entry replacing a local entry, so they will
                        // be identical.
                        UIView.performWithoutAnimation({
                            _self.tableView.reloadSections(IndexSet(integer: entryReplacedInSectionIndex), with: .none)
                        })
                    }
                    _self.tableView.contentOffset = contentOffset
                }
            }
        }
        
        // When an entry is deleted, remove it from the table.
        deleteEntryObserver = NotificationCenter.default.addObserver(
            forName: Constants.NotificationName.deleteEntry,
            object: nil,
            queue: OperationQueue.main)
        { [weak self] (notification: Notification) in
            
            if let _self = self,
                let entry = notification.object as? Entry,
                let entryDeletedInSectionIndex = _self.deleteEntry(entry) {
                
                DispatchQueue.main.async {
                    
                    // Reload the section the entry was deleted from.
                    _self.tableView.reloadSections(IndexSet(integer: entryDeletedInSectionIndex), with: .fade)
                }
            }
        }
        
        // Get existing entries.
        getEntries()
    }
    
    // When the settings button is pressed, push the SettingsViewController.
    @IBAction func onSettingsButton(_ sender: UIBarButtonItem) {
        
        let settingsViewController = SettingsViewController(nibName: nil, bundle: nil)
        navigationController?.pushViewController(settingsViewController, animated: true)
    }
    
    // When the compose is pressed, present the EditEntryViewController modally.
    @IBAction func onComposeButton(_ sender: UIBarButtonItem)
    {
        let editEntryViewController = EditEntryViewController(nibName: nil, bundle: nil)
        let navigationController = UINavigationController(rootViewController: editEntryViewController)
        present(navigationController, animated: true, completion: nil)
    }
    
    // Get existing entries for the authenticating user.
    func getEntries() {
        
        willRequest()
        
        FirebaseClient.shared.getEntries(
            success: { () in
                
                self.requestDidSucceed(true)
            },
            failure: { (error: Error) in
                
                self.requestDidSucceed(false)
            })
    }
    
    // Add the specified new entry to the tableView sections. Returns true
    // if a new section was added, false otherwise.
    func addNewEntry(_ entry: Entry) -> Bool {
        
        let (week, year) = Constants.getWeekYear(date: entry.createdDate)
        
        let section: TimelineSection
        let sectionWasAdded: Bool
        if sections.count > 0 && sections[0].week == week && sections[0].year == year {
            
            section = sections[0]
            sectionWasAdded = false
        }
        else {
            
            section = TimelineSection(week: week, year: year)
            sections.insert(section, at: 0)
            sectionWasAdded = true
        }
        
        section.prepend(entry: entry)
        
        return sectionWasAdded
    }
    
    // Replaces the specified entry in the tableView, if found. Returns the
    // section index of the replaced entry, or nil if no entry was replaced.
    func replaceEntry(withId entryId: String, replacementEntry: Entry) -> Int? {
        
        for (sectionIndex, section) in sections.enumerated() {
            
            let entryWasReplaced = section.replace(entryWithId: entryId, replacementEntry: replacementEntry)
            if entryWasReplaced {
                
                return sectionIndex
            }
        }
        return nil
    }
    
    // Deletes the specified entry from the tableView, if found. Returns the
    // section index of the deleted entry, or nil if no entry was deleted.
    func deleteEntry(_ entry: Entry) -> Int? {
        
        for (sectionIndex, section) in sections.enumerated() {
            
            // To simplify the tableView reloading code, we currently do not
            // remove a section with zero entries.
            let entryWasDeleted = section.remove(entry: entry)
            if entryWasDeleted {
                
                return sectionIndex
            }
        }
        return nil
    }
    
    // Push the ViewEntryScrollingViewController for the specified entry.
    func pushViewEntryViewController(forEntry entry: Entry) {
        
        let viewEntryViewController = ViewEntryScrollingViewController(nibName: nil, bundle: nil)
        viewEntryViewController.entry = entry
        navigationController?.pushViewController(viewEntryViewController, animated: true)
    }
}

// UITableView methods
extension TimelineViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return sections[section].title
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        
        // Only use upper case for the first letter of each word.
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.text = header.textLabel?.text?.capitalized
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 30
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return sections[section].rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.CellReuseIdentifier.timelineCell) as! TimelineTableViewCell
        
        // Set the cell contents.
        cell.setData(entry: sections[indexPath.section].get(entryAtRow: indexPath.row), delegate: self)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let entry = sections[indexPath.section].get(entryAtRow: indexPath.row)
        if entry.isLocal && entry.isLocalMarkedForDelete {
            
            // Hide cells of entries marked for deletion.
            return 0
        }
        else {
            
            return tableView.rowHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Push the ViewEntryScrollingViewController.
        pushViewEntryViewController(
            forEntry: sections[indexPath.section].get(entryAtRow: indexPath.row))
        
        // Do not leave rows selected.
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        // Only allow swipe to delete for user's entries which are
        // not temporary "local" entries.
        let entry = sections[indexPath.section].get(entryAtRow: indexPath.row)
        return !entry.isLocal
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        // Swipe to delete
        if editingStyle == .delete {
            
            EntryBroker.shared.deleteEntry(entry: sections[indexPath.section].get(entryAtRow: indexPath.row))
        }
    }
}

// TimelineTableViewCell methods
extension TimelineViewController: TimelineTableViewCellDelegate {
    
    func timelineCellWasTapped(_ cell: TimelineTableViewCell) {
        
        // Push the ViewEntryScrollingViewController when a cell was tapped, but
        // a tableView didSelectRowAt call did not occur.
        if let entry = cell.entry {
            
            pushViewEntryViewController(forEntry: entry)
        }
    }
}
