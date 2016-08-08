//
//  AppDelegate.swift
//  AppleRSSNewsReader
//
//  Created by Vyacheslav Nagornyak on 6/18/16.
//  Copyright © 2016 Vyacheslav Nagornyak. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

	var window: UIWindow?
	
	// MARK: - UIApplicationDelegate

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		
		// Setup UISplitViewController appearance and delegate
		let splitViewController = self.window!.rootViewController as! UISplitViewController
		let navigationController = splitViewController.viewControllers.last as! UINavigationController
		navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
		splitViewController.delegate = self

		// Create reference to managedObjectContext
		let masterNavigationController = splitViewController.viewControllers.first as! UINavigationController
		let controller = masterNavigationController.topViewController as! MasterViewController
		controller.managedObjectContext = self.managedObjectContext
		return true
	}
	
	func applicationWillTerminate(application: UIApplication) {
		self.saveContext()
	}

	// MARK: - UISplitViewController

	func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
	    guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
	    guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
	    if topAsDetailController.contentItem == nil {
			// Configure DetailViewController to represent valid state while it's empty
			topAsDetailController.configureView()
	        return true
	    }
	    return false
	}
	
	// MARK: - Application folder for data

	lazy var applicationDocumentsDirectory: NSURL = {
	    let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
		return urls.last!
	}()
	
	// MARK: - Object Model
	
	lazy var managedObjectModel: NSManagedObjectModel = {
	    let modelURL = NSBundle.mainBundle().URLForResource("AppleRSSNewsReader", withExtension: "momd")!
	    return NSManagedObjectModel(contentsOfURL: modelURL)!
	}()

	// MARK: - Store Coordinator
	
	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
	    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
	    let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
	    do {
	        try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
	    } catch {
			// If we got here, then the data storage was changed and now there is invalid storage structure on
			// device. Usualy, this is not going to happen, because application should be shipped with no changes
			// of data structure. But, if we update our app and change data structure, then we will have to
			// implement data migration procces. For now it is not needed
	        // Report any error we got.
	        var dict = [String: AnyObject]()
	        dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
	        dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."
	        dict[NSUnderlyingErrorKey] = error as NSError
	        let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
			
	        print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
			assert(false, "Store Coordinator failed to initialize. Perhaps, there are differences between storage format on device and in app.")
	    }
	    
	    return coordinator
	}()
	
	// MARK: - Object Context
	
	lazy var managedObjectContext: NSManagedObjectContext = {
	    let coordinator = self.persistentStoreCoordinator
	    var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
	    managedObjectContext.persistentStoreCoordinator = coordinator
	    return managedObjectContext
	}()

	// MARK: - Core Data Saving support

	func saveContext () {
	    if managedObjectContext.hasChanges {
			// Since we are calling this method only when app is
			// terminating there will be no time to handle errors
			try! managedObjectContext.save()
	    }
	}

}

