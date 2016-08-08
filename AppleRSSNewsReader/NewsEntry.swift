//
//  NewsEntry.swift
//  AppleRSSNewsReader
//
//  Created by Vyacheslav Nagornyak on 6/26/16.
//  Copyright © 2016 Vyacheslav Nagornyak. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class NewsEntry: NSManagedObject {
	var title: String!
	var content: String!
	var date: NSDate!
	var link: String!
	var image: UIImage?
}