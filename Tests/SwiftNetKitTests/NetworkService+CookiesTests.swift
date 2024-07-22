import XCTest
@testable import SwiftNetKit

class NetworkServiceCookiesTests: XCTestCase {
    
    var networkService: NetworkService!
    
    override func setUp() {
        super.setUp()
        networkService = NetworkService()
        resetAllCookies()
    }
    
    override func tearDown() {
        resetAllCookies()
        networkService = nil
        super.tearDown()
    }
    
    func resetAllCookies() {
        HTTPCookieStorage.shared.cookies?.forEach {
            HTTPCookieStorage.shared.deleteCookie($0)
        }
        UserDefaults.standard.removeObject(forKey: "savedCookies")
    }
    
    func createTestCookie(name: String, value: String, domain: String, expires: Date? = nil) -> HTTPCookie {
        return HTTPCookie(properties: [
            .domain: domain,
            .path: "/",
            .name: name,
            .value: value,
            .secure: "FALSE",
            .expires: expires ?? Date().addingTimeInterval(600)
        ])!
    }
    
    func testGetAllCookies() {
        let testCookie = createTestCookie(name: "test", value: "cookie", domain: "example.com")
        HTTPCookieStorage.shared.setCookie(testCookie)
        
        let cookies = networkService.getAllCookies()
        
        XCTAssertEqual(cookies.count, 1)
        XCTAssertEqual(cookies.first?.name, "test")
    }
    
    func testGetCookiesForURL() {
        let url = URL(string: "https://example.com")!
        let testCookie = createTestCookie(name: "test", value: "cookie", domain: "example.com")
        HTTPCookieStorage.shared.setCookie(testCookie)
        
        let cookies = networkService.getCookiesForURL(for: url)
        
        XCTAssertEqual(cookies.count, 1)
        XCTAssertEqual(cookies.first?.name, "test")
    }
    
    func testRemoveCookiesMatchingCriteria() {
        let testCookie = createTestCookie(name: "test", value: "cookie", domain: "example.com")
        HTTPCookieStorage.shared.setCookie(testCookie)
        
        networkService.removeCookies(matching: [.name: "test"])
        
        let cookies = networkService.getAllCookies()
        XCTAssertEqual(cookies.count, 0)
    }
    
    func testResetCookies() {
        let testCookie1 = createTestCookie(name: "test1", value: "cookie1", domain: "example.com")
        let testCookie2 = createTestCookie(name: "test2", value: "cookie2", domain: "example.com")
        HTTPCookieStorage.shared.setCookie(testCookie1)
        HTTPCookieStorage.shared.setCookie(testCookie2)
        
        networkService.resetCookies()
        
        let cookies = networkService.getAllCookies()
        XCTAssertEqual(cookies.count, 0)
    }
    
    func testSaveCookiesToSession() {
        let url = URL(string: "https://example.com")!
        let testCookie = createTestCookie(name: "test", value: "cookie", domain: "example.com")
        
        networkService.saveCookiesToSession([testCookie], for: url)
        
        let cookies = networkService.getCookiesForURL(for: url)
        XCTAssertEqual(cookies.count, 1)
        XCTAssertEqual(cookies.first?.name, "test")
    }
    
    func testSaveCookiesToUserDefaults() {
        let testCookie = createTestCookie(name: "test", value: "cookie", domain: "example.com")
        HTTPCookieStorage.shared.setCookie(testCookie)
        
        networkService.saveCookiesToUserDefaults([testCookie])
        
        let savedData = UserDefaults.standard.array(forKey: "savedCookies") as? [Data]
        XCTAssertNotNil(savedData)
        XCTAssertEqual(savedData?.count, 1)
    }
    
    func testLoadCookiesFromUserDefaults() {
        let testCookie = createTestCookie(name: "test", value: "cookie", domain: "example.com")
        HTTPCookieStorage.shared.setCookie(testCookie)
        networkService.saveCookiesToUserDefaults([testCookie])
        
        networkService.resetCookies() // Clear cookies from session
        networkService.loadCookiesFromUserDefaults()
        
        let cookies = networkService.getAllCookies()
        XCTAssertEqual(cookies.count, 1)
        XCTAssertEqual(cookies.first?.name, "test")
    }
    
    func testRemoveExpiredCookies() {
        let expiredCookie = createTestCookie(name: "expired", value: "cookie", domain: "example.com", expires: Date().addingTimeInterval(-100))
        HTTPCookieStorage.shared.setCookie(expiredCookie)
        
        networkService.removeExpiredCookies()
        
        let cookies = networkService.getAllCookies()
        XCTAssertEqual(cookies.count, 0)
    }
}
