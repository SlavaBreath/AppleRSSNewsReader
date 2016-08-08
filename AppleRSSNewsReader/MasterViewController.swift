//
//  MasterViewController.swift
//  AppleRSSNewsReader
//
//  Created by Vyacheslav Nagornyak on 6/18/16.
//  Copyright © 2016 Vyacheslav Nagornyak. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, NSXMLParserDelegate {

	@IBOutlet weak var refreshButton: UIBarButtonItem!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var newsTableView: UITableView!
	
	var managedObjectContext: NSManagedObjectContext? = nil
	
	// MARK: - XMLParser vars
	
	var parser: NSXMLParser!
	var currentElement: String! = String()
	var currentTitle: String! = String()
	var currentContent: String! = String()
	var currentDate: String! = String()
	var currentLink: String! = String()
	var itemBegin: Bool = false
	
	// MARK: - UIView
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		// Show activity indicator while we loading news from server
		if let tableView = self.newsTableView, let activity = self.activityIndicator {
			if tableView.numberOfRowsInSection(0) == 0 {
				activity.hidden = false
				activity.startAnimating()
			}
		}
		
		// Start parsing
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			self.startParsing()
		}
	}

	override func viewWillAppear(animated: Bool) {
		if let indexPath = self.newsTableView.indexPathForSelectedRow where self.splitViewController!.collapsed {
			self.newsTableView.deselectRowAtIndexPath(indexPath, animated: animated)
		}
		
		super.viewWillAppear(animated)
	}
	
	// MARK: - Actions
	
	@IBAction func refreshButtonPressed(sender: UIBarButtonItem) {
		sender.enabled = false
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
			self.startParsing()
		}
	}
	
	// MARK: - Segues

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = self.newsTableView.indexPathForSelectedRow {
				let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
				let object = fetchedResultsController.objectAtIndexPath(indexPath)
				controller.contentItem = object
				controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
				controller.navigationItem.leftItemsSupplementBackButton = true
		    }
		}
	}

	// MARK: - Table View
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return fetchedResultsController.sections?.count ?? 0
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sectionInfo = self.fetchedResultsController.sections![section]
		return sectionInfo.numberOfObjects
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("NewsCell", forIndexPath: indexPath) as! NewsTableViewCell
		let object = fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
		configureCell(cell, withObject: object)
		return cell
	}

	func configureCell(cell: UITableViewCell, withObject object: NSManagedObject) {
		guard
			let title = object.valueForKey("title"),
			let content = object.valueForKey("content"),
			let date = object.valueForKey("date")
			else {
				return
		}
		
		let myCell = cell as! NewsTableViewCell
		myCell.titleLabel!.text = title.description
		myCell.contentLabel.text = content.description
		let formatter = NSDateFormatter()
		formatter.dateStyle = .LongStyle
		myCell.dateLabel!.text = formatter.stringFromDate(date as! NSDate)
	}

	// MARK: - Fetched results controller

	var fetchedResultsController: NSFetchedResultsController {
	    if _fetchedResultsController != nil {
	        return _fetchedResultsController!
	    }
	    
	    let fetchRequest = NSFetchRequest()
	    let entity = NSEntityDescription.entityForName("NewsEntry", inManagedObjectContext: self.managedObjectContext!)
	    fetchRequest.entity = entity
	    
		// Get 20 items at a time
	    fetchRequest.fetchBatchSize = 20
	    
		// Sort news by date
	    let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
	    fetchRequest.sortDescriptors = [sortDescriptor]
	    
		// Create controller with the given request. Enable cashe for performance
	    let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
	    aFetchedResultsController.delegate = self
	    _fetchedResultsController = aFetchedResultsController
	    
	    do {
	        try _fetchedResultsController!.performFetch()
	    } catch {
	         print("Could not perforn fetched request to stored data")
	    }
	    
	    return _fetchedResultsController!
	}    
	var _fetchedResultsController: NSFetchedResultsController? = nil
	
	// Each time we get new data from storage, refresh tableView
	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		self.newsTableView.reloadData()
		self.activityIndicator.stopAnimating()
	}
	
	// MARK: - Parsing
	
	func startParsing() {
		// Since we are Apple News App this link can be here
		let url = NSURL(string: "http://developer.apple.com/news/rss/news.rss")
		let URLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
		
		let task = URLSession.dataTaskWithURL(url!) { (data, response, error) in
			if let data = data {
				self.parser = NSXMLParser(data: data)
				self.parser.delegate = self
				self.parser.parse()
			} else {
				assert(false, "Error retrieving data from server")
			}
		}
		
		task.resume()
	}
	
	// MARK: - NSXMLParserDelegate
	
	func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
		currentElement = elementName
	}
	
	func parser(parser: NSXMLParser, foundCharacters string: String) {
		switch currentElement {
			case "item":
				itemBegin = true
			case "title":
				if itemBegin && string != "\n" {
					currentTitle! += string
				}
			case "content:encoded":
				if itemBegin && string != "\n" {
					currentContent! += string
				}
			case "pubDate":
				if itemBegin && string != "\n"{
					currentDate! += string
				}
			case "link":
				if itemBegin && string != "\n"{
					currentLink! += string
			}
		default:
			break
		}
	}
	
	func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		if itemBegin {
			if elementName == "title" {
				// Check if we habe already this item. If so, skip it
				for object in fetchedResultsController.fetchedObjects! {
					if object.valueForKey("title")!.description == currentTitle {
						itemBegin = false
						currentTitle = String();
						break
					}
				}
			} else if elementName == "item" {
				// This item is new, save it
				let context = fetchedResultsController.managedObjectContext
				let entity = fetchedResultsController.fetchRequest.entity!
				let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context)
				
				newManagedObject.setValue(currentTitle, forKey: "title")
				
				do {
					let userFriendlyContent = try NSAttributedString(data: (currentContent as NSString).dataUsingEncoding(NSUTF16StringEncoding)! , options: [NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType], documentAttributes: nil)
					newManagedObject.setValue(userFriendlyContent.string, forKey: "content")
				} catch {
					print("Unable to parse content")
				}
				
				let formatter = NSDateFormatter()
				formatter.dateFormat = "eee',' dd MMM yyyy HH:mm:ss zzz"
				let date = formatter.dateFromString(currentDate)
				newManagedObject.setValue(date, forKey: "date")
				newManagedObject.setValue(currentLink, forKey: "link")
				
				// Save the context.
				do {
					try context.save()
				} catch {
					let error = error as NSError
					assert(false, "Failed to save contex with error: \(error)\nInfo: \(error.userInfo)")
				}
				
				// Reset everything
				itemBegin = false
				currentElement = String()
				currentTitle = String()
				currentContent = String()
				currentDate = String()
				currentLink = String()
			}
		}
	}
	
	func parserDidEndDocument(parser: NSXMLParser) {
		dispatch_async(dispatch_get_main_queue()) {
			self.newsTableView.reloadData()
			if let refresh = self.refreshButton {
				refresh.enabled = true
			}
			
			if let activity = self.activityIndicator {
				activity.stopAnimating()
			}
		}
	}

}

