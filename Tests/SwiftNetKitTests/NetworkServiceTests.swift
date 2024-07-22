import XCTest
@testable import SwiftNetKit

final class NetworkServiceTests: XCTestCase {
    var networkService: NetworkService!
    let getURL = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
    let postURL = URL(string: "https://jsonplaceholder.typicode.com/posts")!
    
    override func setUp() {
        super.setUp()
        networkService = NetworkService()
    }
    
    override func tearDown() {
        networkService = nil
        super.tearDown()
    }
    
    func testGetSuccessAsyncAwait() {
        let expectation = XCTestExpectation(description: "Fetch data successfully")
        
        Task {
            do {
                let baseRequest = BaseRequest<Post>(
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
        
        let baseRequest = BaseRequest<Post>(
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
        let baseRequest = BaseRequest<Post>(
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
        let baseRequest = BaseRequest<Post>(
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
        
        let firstRequest = BaseRequest<Post>(
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
        // Disclaimer: This test doesn't necessarily prove included cookies in request
        
        let expectation = XCTestExpectation(description: "Include cookies in request")
        
        let testCookie = createTestCookie(name: "testCookie", value: "cookieValue", domain: "jsonplaceholder.typicode.com")
        networkService.saveCookiesToSession([testCookie], for: getURL)
        
        let baseRequest = BaseRequest<Post>(
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
    
    func testSaveCookiesFromResponse() {
        let expectation = XCTestExpectation(description: "Save cookies from response")
        
        let baseRequest = BaseRequest<Post>(
            url: self.getURL,
            method: .get,
            saveCookiesToSession: true
        )
        
        Task {
            do {
                let _: Post = try await self.networkService.start(baseRequest)
                
                // Verifying cookies are saved to the session
                let cookies = networkService.getAllCookies()
                XCTAssertTrue(cookies.contains(where: { $0.name == "testCookie" }))
                
                expectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLoadCookiesFromUserDefaultsAndUseInRequest() {
        // Disclaimer: This test doesn't necessarily prove included cookies in request
        
        let expectation = XCTestExpectation(description: "Load cookies from UserDefaults and use in request")
        
        let testCookie = createTestCookie(name: "testCookie", value: "cookieValue", domain: "jsonplaceholder.typicode.com")
        networkService.saveCookiesToUserDefaults([testCookie])
        networkService.resetCookies() // Clear cookies from session
        networkService.loadCookiesFromUserDefaults()
        
        let baseRequest = BaseRequest<Post>(
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
}

// 'Post' for testing jsonplaceholder.typicode.com data
struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
