import XCTest
@testable import SwiftNetKit

final class NetworkServiceTests: XCTestCase {
    var networkService: NetworkService!
    let getURL = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
    let postURL = URL(string: "https://jsonplaceholder.typicode.com/posts")!
    
    override func setUp() {
        super.setUp()
        networkService = NetworkService()
        CookieManager.shared.syncCookiesWithUserDefaults = true
        clearAllCookies()
    }
    
    override func tearDown() {
        networkService = nil
        clearAllCookies()
        super.tearDown()
    }
    
    func clearAllCookies() {
        CookieManager.shared.syncCookiesWithUserDefaults = true
        CookieManager.shared.deleteAllCookies()
    }
    
    
    private func createTestCookie(name: String, value: String, domain: String) -> HTTPCookie {
        return HTTPCookie(properties: [
            .domain: domain,
            .path: "/",
            .name: name,
            .value: value,
            .secure: "FALSE",
            .expires: NSDate(timeIntervalSinceNow: 3600)
        ])!
    }
    
    func testGetSuccessAsyncAwait() {
        let expectation = XCTestExpectation(description: "Fetch data successfully")
        
        Task {
            do {
                let baseRequest = Request<Post>(
                    url: self.getURL,
                    method: .get
                )
                let post: Post = try await self.networkService.start(baseRequest)
                XCTAssertEqual(post.userId, 1)
                XCTAssertEqual(post.id, 1)
                
                expectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testGetSuccessClosure() {
        let expectation = XCTestExpectation(description: "Fetch data successfully")
        
        let baseRequest = Request<Post>(
            url: self.getURL,
            method: .get
        )
        
        networkService.start(baseRequest) { result in
            switch result {
            case .success(let post):
                XCTAssertEqual(post.userId, 1)
                XCTAssertEqual(post.id, 1)
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testPostSuccessWithBodyAsyncAwait() {
        let expectation = XCTestExpectation(description: "Post data successfully")
        
        let newPost = Post(userId: 1, id: 101, title: "Foo", body: "Bar")
        let baseRequest = Request<Post>(
            url: self.postURL,
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: .jsonEncodable(newPost)
        )
        
        Task {
            do {
                let createdPost: Post = try await self.networkService.start(baseRequest)
                XCTAssertEqual(createdPost.userId, newPost.userId)
                XCTAssertEqual(createdPost.title, newPost.title)
                XCTAssertEqual(createdPost.body, newPost.body)
                
                expectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testPostSuccessWithBodyClosure() {
        let expectation = XCTestExpectation(description: "Post data successfully")
        
        let newPost = Post(userId: 1, id: 101, title: "Foo", body: "Bar")
        let baseRequest = Request<Post>(
            url: self.postURL,
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: .jsonEncodable(newPost)
        )
        
        networkService.start(baseRequest) { result in
            switch result {
            case .success(let createdPost):
                XCTAssertEqual(createdPost.userId, newPost.userId)
                XCTAssertEqual(createdPost.title, newPost.title)
                XCTAssertEqual(createdPost.body, newPost.body)
                
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCachingBehavior() {
        // Disclaimer: This test doesn't necessarily prove that the request was cached
        
        let expectation = XCTestExpectation(description: "Fetch data and cache it")
        let cacheConfiguration = CacheConfiguration(
            memoryCapacity: 10_000_000,
            diskCapacity: 100_000_000,
            cachePolicy: .returnCacheDataElseLoad
        )
        
        let firstRequest = Request<Post>(
            url: self.getURL,
            method: .get,
            cacheConfiguration: cacheConfiguration
        )
        
        Task {
            do {
                let post: Post = try await self.networkService.start(firstRequest)
                XCTAssertEqual(post.userId, 1)
                XCTAssertEqual(post.id, 1)
                
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                let secondRequest = firstRequest
                let cachedPost: Post = try await self.networkService.start(secondRequest)
                
                XCTAssertEqual(post.userId, cachedPost.userId)
                XCTAssertEqual(post.id, cachedPost.id)
                
                expectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testIncludeCookiesInRequest() {
        let expectation = XCTestExpectation(description: "Include cookies in request")
        
        let testCookie = createTestCookie(name: "testCookie", value: "cookieValue", domain: "jsonplaceholder.typicode.com")
        let testCookie2 = createTestCookie(name: "testCookie2", value: "cookieValue2", domain: "jsonplaceholder.typicode.com")
        
        CookieManager.shared.saveCookiesToSession([testCookie, testCookie2], for: getURL)
        
        let baseRequest = Request<Post>(
            url: self.getURL,
            method: .get,
            includeCookies: true
        )
        
        Task {
            do {
                let _: Post = try await self.networkService.start(baseRequest)
                expectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testIncludeCookiesFromUserDefaultsInRequest() {
        let expectation = XCTestExpectation(description: "Include cookies from user defaults in request")
        
        let testCookie = createTestCookie(name: "testCookieUD", value: "cookieValueUD", domain: "jsonplaceholder.typicode.com")
        CookieManager.shared.saveCookiesToUserDefaults([testCookie])
        
        let baseRequest = Request<Post>(
            url: self.getURL,
            method: .get,
            includeCookies: true
        )
        
        Task {
            do {
                let _: Post = try await self.networkService.start(baseRequest)
                expectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testIncludeCookiesFromBothSessionAndUserDefaultsInRequest() {
        let expectation = XCTestExpectation(description: "Include cookies from both session and user defaults in request")
        
        let testCookie = createTestCookie(name: "testCookieSession", value: "cookieValueSession", domain: "jsonplaceholder.typicode.com")
        let testCookieUD = createTestCookie(name: "testCookieUD", value: "cookieValueUD", domain: "jsonplaceholder.typicode.com")
        
        CookieManager.shared.saveCookiesToSession([testCookie], for: getURL)
        CookieManager.shared.saveCookiesToUserDefaults([testCookieUD])
        
        let baseRequest = Request<Post>(
            url: self.getURL,
            method: .get,
            includeCookies: true
        )
        
        Task {
            do {
                let _: Post = try await self.networkService.start(baseRequest)
                expectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// 'Post' for testing jsonplaceholder.typicode.com data
struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
