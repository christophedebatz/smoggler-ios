//
//  NSCoder.swift
//  smoggler
//
//  Created by Christophe de Batz on 30/11/2017.
//  Copyright © 2017 Christophe de Batz. All rights reserved.
//

import Foundation

extension NSCoder {
    class func empty() -> NSCoder {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.finishEncoding()
        return NSKeyedUnarchiver(forReadingWith: data as Data)
    }
}
