//
//  LogViewController.swift
//  Dog Log
//
//  Created by Brian Partridge on 7/9/16.
//  Copyright © 2016 Pear Tree Labs. All rights reserved.
//

import UIKit
import CoreData

class LogViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    
    // MARK: - Private Properties
    
    private var actionButtonsByType: [Type: UIButton] = [:]
    
    private var tableView: UITableView = {
        let t = UITableView(frame: CGRectZero, style: .Plain)
        t.translatesAutoresizingMaskIntoConstraints = false
        return t
    }()
    private let actionBar: UIStackView = {
        let s = UIStackView()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.axis = .Horizontal
        s.distribution = .FillEqually
        return s
    }()

    // MARK: - Internal Properties
    
    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    var eventManager: EventManager!
    
    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        view.addSubview(actionBar)
        
        let views = ["table": tableView, "bar": actionBar]
        let metrics = ["barHeight":  64]
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[table]|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[bar]|", options: [], metrics: metrics, views: views))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[table][bar(barHeight)]|", options: [], metrics: metrics, views: views))
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "eventCell")
        
        // The compiler didn't like when I tried to populate this in init...
        actionButtonsByType = {
            var results: [Type: UIButton] = [:]
            for type in Type.allValues {
                results[type] = self.actionButtonForType(type)
            }
            return results
        }()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: animated)
        }
        
        updateActionBar()
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("eventCell", forIndexPath: indexPath)
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Event
        self.configureCell(cell, withEvent: object)
        return cell
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
                
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                //print("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    private let sectionDateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .NoStyle
        return formatter
    }()
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let firstEvent = fetchedResultsController.sections?[section].objects?.first as? Event,
            dayStamp = firstEvent.dayStamp else { return "Unknown" }
        return sectionDateFormatter.stringFromDate(dayStamp)
    }

    private let cellDateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .NoStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    func configureCell(cell: UITableViewCell, withEvent event: Event) {
        cell.textLabel!.text = "\(event.enumType.emojiDescription) at \(cellDateFormatter.stringFromDate(event.timeStamp))"
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("Event", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        fetchRequest.fetchBatchSize = 20
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: false)]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: "dayStamp", cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             //print("Unresolved error \(error), \(error.userInfo)")
             abort()
        }
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController? = nil

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, withEvent: anObject as! Event)
            case .Move:
                tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
        updateActionBar()
    }
    
    // MARK: - Private Methods
    
    private func updateActionBar() {
        // Populate the bar if not done yet.
        if (actionBar.arrangedSubviews.isEmpty) {
            actionButtonsByType.values.forEach { actionBar.addArrangedSubview($0) }
        }
        
        // Temporarily hide all the buttons. Yay, stack view!
        actionBar.arrangedSubviews.forEach { $0.hidden = true }
        
        // Display only the buttons that shouldn't be hidden.
        let visibleEventTypes: [Type] = eventManager.isWalking ? [.Pee, .Poop, .WalkEnd] : [.WalkBegin]
        visibleEventTypes.forEach { actionButtonsByType[$0]?.hidden = false }
    }
    
    private func insertEvent(ofType type: Type) {
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let event = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as! Event
        
        event.updateTimeStamp(NSDate())
        event.enumType = type
        
        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //print("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }
    
    private func actionButtonForType(type: Type) -> UIButton {
        let button = UIButton(type: .System)
        button.setTitle(type.emojiDescription, forState: .Normal)
        button.backgroundColor = type.color
        button.tag = type.rawValue
        button.addTarget(self, action: #selector(actionTapped), forControlEvents: .TouchUpInside)
        return button
    }
    
    // MARK: - Actions
    
    @objc func actionTapped(sender: UIButton) {
        insertEvent(ofType: Type(rawValue: sender.tag)!)
    }
}

class EventManager {
    
    private let managedObjectContext: NSManagedObjectContext
    
    var isWalking: Bool {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName("Event", inManagedObjectContext: self.managedObjectContext)
        fetchRequest.fetchBatchSize = 1
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timeStamp", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "type == \(Type.WalkBegin.rawValue) OR type == \(Type.WalkEnd.rawValue)")
        
        let results = try! managedObjectContext.executeFetchRequest(fetchRequest)
        guard let firstResult = results.first else { return false }
        
        guard let event = firstResult as? Event else { fatalError() }
        switch event.enumType {
        case .WalkBegin: return true
        case .WalkEnd: return false
        default: fatalError()
        }
    }
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
}
