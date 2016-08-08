//
//  InfoViewController.swift
//  AppleRSSNewsReader
//
//  Created by Vyacheslav Nagornyak on 6/18/16.
//  Copyright © 2016 Vyacheslav Nagornyak. All rights reserved.
//

import UIKit
import MessageUI

class InfoViewController: UIViewController, MFMailComposeViewControllerDelegate {

	// MARK: - UIViewController
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
	
	// MARK: - Actions
	
	@IBAction func emailPressed(sender: UIButton) {
		let mailComposeViewController = configuredMailComposeViewController()
		if MFMailComposeViewController.canSendMail() {
			self.presentViewController(mailComposeViewController, animated: true, completion: nil)
		} else {
			showSendMailErrorAlert()
		}
	}
	
	@IBAction func donePressed(sender: AnyObject) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	// MARK: - MFMailComposeViewControllerDelegate
	
	func configuredMailComposeViewController() -> MFMailComposeViewController {
		let mailComposerVC = MFMailComposeViewController()
		mailComposerVC.mailComposeDelegate = self
		
		mailComposerVC.setToRecipients(["nagornak.slava@gmail.com"])
		mailComposerVC.setSubject("Apple RSS News Reader Feedback")
		mailComposerVC.setMessageBody("Hi!\n\nI'm usig your app and have something to say.\n", isHTML: false)
		
		return mailComposerVC
	}
	
	func showSendMailErrorAlert() {
		let alert = UIAlertController(title: "Could not send email", message: "Seems like your device cannot send email. Please, check your email configuration and try again.", preferredStyle: .Alert)
		let cancel = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
		alert.addAction(cancel)
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
		controller.dismissViewControllerAnimated(true, completion: nil)
		
	}
}
