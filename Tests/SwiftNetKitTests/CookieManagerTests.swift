//
//  CookieManagerTests.swift
//
//
//  Created by Sam Gilmore on 7/22/24.
//

import XCTest
@testable import SwiftNetKit

class CookieManagerTests: XCTestCase {
    
    let testURL = URL(string: "https://jsonplaceholder.typicode.com")!
    
    override func setUp() {
        super.setUp()
        CookieManager.shared.syncCookiesWithUserDefaults = true
        CookieManager.shared.deleteAllCookies()
    }
    
    override func tearDown() {
        CookieManager.shared.syncCookiesWithUserDefaults = true
        CookieManager.shared.deleteAllCookies()
        super.tearDown()
    }
    
    func createTestCookie(name: String, value: String, domain: String) -> HTTPCookie {
        return HTTPCookie(properties: [
            .domain: domain,
            .path: "/",
            .name: name,
            .value: value,
            .expires: Date().addingTimeInterval(3600)
        ])!
    }
    
    func testSaveAndLoadCookiesFromUserDefaults() {
        let testCookie = createTestCookie(name: "testCookie", value: "cookieValue", domain: testURL.host!)
        
        CookieManager.shared.saveCookiesToUserDefaults([testCookie])
        CookieManager.shared.loadCookiesFromUserDefaults()
        
        let cookies = CookieManager.shared.getCookiesForURL(for: testURL)
        
        XCTAssertEqual(cookies.count, 1)
        XCTAssertEqual(cookies.first?.name, "testCookie")
        XCTAssertEqual(cookies.first?.value, "cookieValue")
    }
    
    func testIncludeCookiesInRequest() {
        let expectation = XCTestExpectation(description: "Include cookies in request")
        
        let testCookie = createTestCookie(name: "testCookie", value: "cookieValue", domain: testURL.host!)
        let testCookie2 = createTestCookie(name: "testCookie2", value: "cookieValue2", domain: testURL.host!)
        
        CookieManager.shared.saveCookiesToSession([testCookie, testCookie2], for: testURL)
        
        var urlRequest = URLRequest(url: testURL)
        CookieManager.shared.includeCookiesIfNeeded(for: &urlRequest, includeCookies: true)
        
        let cookiesHeader = urlRequest.allHTTPHeaderFields?["Cookie"]
        
        XCTAssertNotNil(cookiesHeader)
        XCTAssertTrue(cookiesHeader!.contains("testCookie=cookieValue"))
        XCTAssertTrue(cookiesHeader!.contains("testCookie2=cookieValue2"))
        
        expectation.fulfill()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testSyncCookies() {
        let testCookie = createTestCookie(name: "testCookie", value: "cookieValue", domain: testURL.host!)
        
        CookieManager.shared.saveCookiesToUserDefaults([testCookie])
        CookieManager.shared.syncCookies()
        
        let cookies = CookieManager.shared.getCookiesForURL(for: testURL)
        
        XCTAssertEqual(cookies.count, 1)
        XCTAssertEqual(cookies.first?.name, "testCookie")
        XCTAssertEqual(cookies.first?.value, "cookieValue")
    }
    
    func testDeleteExpiredCookies() {
        let expiredCookie = HTTPCookie(properties: [
            .domain: testURL.host!,
            .path: "/",
            .name: "expiredCookie",
            .value: "expiredValue",
            .expires: Date().addingTimeInterval(-3600)
        ])!
        
        CookieManager.shared.saveCookiesToUserDefaults([expiredCookie])
        CookieManager.shared.deleteExpiredCookies()
        
        let cookies = CookieManager.shared.getAllCookiesFromSession()
        
        XCTAssertEqual(cookies.count, 0)
    }
    
    func testCleanExpiredCookies() {
        let expiredCookie = HTTPCookie(properties: [
            .domain: testURL.host!,
            .path: "/",
            .name: "expiredCookie",
            .value: "expiredValue",
            .expires: Date().addingTimeInterval(-3600)
        ])!
        
        let validCookie = createTestCookie(name: "validCookie", value: "validValue", domain: testURL.host!)
        
        CookieManager.shared.saveCookiesToUserDefaults([expiredCookie, validCookie])
        CookieManager.shared.cleanExpiredCookies()
        
        let cookies = CookieManager.shared.getCookiesForURL(for: testURL)
        
        XCTAssertEqual(cookies.count, 1)
        XCTAssertEqual(cookies.first?.name, "validCookie")
        XCTAssertEqual(cookies.first?.value, "validValue")
    }
}
