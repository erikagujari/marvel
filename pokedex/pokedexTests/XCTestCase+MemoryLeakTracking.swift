//
//  XCTestCase+MemoryLeakTracking.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 26/10/21.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should be deallocated, potentially memory leak", file: file, line: line)
        }
    }
}
