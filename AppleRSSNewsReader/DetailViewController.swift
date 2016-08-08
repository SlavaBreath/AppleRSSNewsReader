//
//  DetailViewController.swift
//  AppleRSSNewsReader
//
//  Created by Vyacheslav Nagornyak on 6/18/16.
//  Copyright © 2016 Vyacheslav Nagornyak. All rights reserved.
//

import UIKit
import CoreData
import SafariServices

class DetailViewController: UIViewController {

	// MARK: - Outlets
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var contentTextView: UITextView!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var emptyControllerLabel: UILabel!
	@IBOutlet weak var newsImage: UIImageView!
	@IBOutlet weak var contentOffsetConstraint: NSLayoutConstraint!
	@IBOutlet weak var contentScrollView: UIScrollView!
	@IBOutlet weak var contentHolderView: UIView!
	
	// MARK: - Content vars
	
	var contentItem: AnyObject?
	var link: String! = String()
	enum Extension {
		case JPG
		case PNG
		case NO_EXTENSION
	}
	var imgExt: Extension! = .NO_EXTENSION
	
	// MARK: - Content hadler
	
	func configureView() {
		// Update the user interface for the detail item.
		if let news = contentItem {
			if let title = titleLabel {
				title.text = news.valueForKey("title")!.description
			}
		    if let content = contentTextView {
		        content.text = news.valueForKey("content")!.description
		    }
			if let date = self.dateLabel {
				let formatter = NSDateFormatter()
				formatter.dateStyle = .LongStyle
				date.text = formatter.stringFromDate(news.valueForKey("date") as! NSDate)
			}
			if let url = news.valueForKey("link")?.description {
				link = url
			}
			if let empty = self.emptyControllerLabel {
				empty.hidden = true
			}
			
			if let image = news.valueForKey("image") {
				guard let imageView = self.newsImage else { return }
				imageView.image = UIImage(data: image as! NSData)
				showImageOnView()
			} else {
				if let link = self.link {
					
					dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
						guard let url = self.findImageURLString(url: link),
							let imageView = self.newsImage else { return }
						
						imageView.downloadFrom(url: url) {
							self.showImageOnView()
							self.saveImage()
						}
					})
				}
			}
			
			if let scroll = contentScrollView {
				scroll.hidden = false
				scroll.contentSize = self.view.bounds.size
			}
			
		} else {
			// Default configuration
			if let scroll = contentScrollView {
				scroll.hidden = true
			}
			
			if let empty = emptyControllerLabel {
				empty.hidden = false
			}
			
			navigationItem.title = String()
		}
	}
	
	// MARK: - Actions
	
	@IBAction func shareButtonPressed(sender: UIBarButtonItem) {
		let safariView = SFSafariViewController(URL: NSURL(string: link)!)
		presentViewController(safariView, animated: true, completion: nil)
	}
	

	// MARK: - UIViewController
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		configureView()
		// Seems like my Xcode doesn't wank to configure this correctly from IB,
		// so I did it really hardcoded
		contentTextView.tintColor = UIColor(red: 0.44, green: 0.76, blue: 0.32, alpha: 1.0)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Service functions
	
	func showImageOnView() {
		guard let image = self.newsImage else { return }
		guard let constraint = self.contentOffsetConstraint else { return }
		image.hidden = false
		constraint.constant = 114
	}
	
	func saveImage() {
		guard let image = self.newsImage else { return }
		
		// Create request to data to save image
		let predicate = NSPredicate(format: "title == %@", (contentItem?.title)!)
		let fetchRequest = NSFetchRequest(entityName: "NewsEntry")
		fetchRequest.predicate = predicate
		let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
		
		do {
			let object = try context.executeFetchRequest(fetchRequest)
			switch imgExt! {
			case .PNG:
				let data = UIImagePNGRepresentation(image.image!)
				object.first!.setValue(data, forKey: "image")
			case .JPG:
				let data = UIImageJPEGRepresentation(image.image!, 0.0)
				object.first!.setValue(data, forKey: "image")
			default:
				break
			}
			do {
				try context.save()
			} catch {
				print("Error while saving context")
			}
		} catch {
			print("Error while getting an object from storage")
		}
	}
	
	func findImageURLString(url link: String) -> String? {
		let url = NSURL(string: link)
		var resultString: String?
		do {
			let HTMLString = try NSString(contentsOfURL: url!, encoding: NSUTF8StringEncoding)
			let startSearchString = "<img class=\"article-image center\" src=\""
			let pngSearchString = ".png"
			let jpgSearchString = ".jpg"
			let range = HTMLString.rangeOfString(startSearchString)
			// If we are lucky to find image for news, then load it
			if range.length > 0 {
				var endRange = HTMLString.rangeOfString(pngSearchString)
				
				if endRange.length > 0 {
					resultString = HTMLString.substringWithRange(NSRange(location: range.location + range.length, length: endRange.location + endRange.length - (range.location + range.length)))
					imgExt = .PNG
				}
				
				endRange = HTMLString.rangeOfString(jpgSearchString)
				if endRange.length > 0 {
					resultString = HTMLString.substringWithRange(NSRange(location: range.location + range.length, length: endRange.location + endRange.length - (range.location + range.length)))
					imgExt = .JPG
				}
			}
		} catch {
			print("Could not get HTML from link: \(link)")
		}
		
		let appleNewsDomain = "https://developer.apple.com"
		
		if resultString != nil && !(resultString?.hasPrefix("http"))! {
			resultString = appleNewsDomain + resultString!
		}
		
		return resultString
	}
}

// MARK: - UIImageView extension

extension UIImageView {
	func downloadFrom(url link: String, completion: (() -> Void)?) {
		guard let url = NSURL(string: link) else { return }
		NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
			guard let httpURLResponse = response as? NSHTTPURLResponse where httpURLResponse.statusCode == 200,
				let mimeType = response?.MIMEType where mimeType.hasPrefix("image"),
				let data = data where error == nil,
				let image = UIImage(data: data)
				else {
					return
				}
			
			dispatch_async(dispatch_get_main_queue(), {
				self.image = image
				if let completion = completion {
					completion()
				}
			})
		}.resume()
	}
}