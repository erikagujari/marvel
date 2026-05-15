//
//  XCTestCase+MemoryLeakTracking.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 26/10/21.
//

import XCTest

// Box that holds a weak reference and is safe to send across isolation domains.
// `addTeardownBlock` requires a `@Sendable` closure, but `AnyObject` isn't Sendable;
// boxing the weak reference lets the teardown closure observe deallocation safely.
private final class WeakBox: @unchecked Sendable {
    weak var instance: AnyObject?
    init(_ instance: AnyObject) { self.instance = instance }
}

extension XCTestCase {
    func trackForMemoryLeaks(instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        let box = WeakBox(instance)
        addTeardownBlock { @MainActor in
            // SwiftUI / UIKit defer some releases to the next run-loop turn.
            // Poll for deallocation before asserting so genuine post-teardown
            // releases are not flagged as leaks.
            for _ in 0..<10 where box.instance != nil {
                RunLoop.main.run(until: Date().addingTimeInterval(0.02))
            }
            XCTAssertNil(box.instance, "Instance should be deallocated, potentially memory leak", file: file, line: line)
        }
    }
}
