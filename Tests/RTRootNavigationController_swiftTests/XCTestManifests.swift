import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RTRootNavigationController_swiftTests.allTests),
    ]
}
#endif
