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
        
        let baseRequest = Request<Post>(
            url: self.getURL,
            method: .get,
            includeCookies: true
        )
        
        let testCookie = createTestCookie(name: "testCookie", value: "cookieValue", domain: "jsonplaceholder.typicode.com")
        let testCookie2 = createTestCookie(name: "testCookie2", value: "cookieValue2", domain: "jsonplaceholder.typicode.com")
        
        baseRequest.addTempCookie(name: "temp1", value: "temp1val")
        
        CookieManager.shared.saveCookiesToSession([testCookie, testCookie2])
        
        baseRequest.addTempCookie(name: "temp2", value: "temp2val")
        
        let newRequest = Request<Post>(
            url: self.getURL,
            method: .get,
            includeCookies: true
        )
        
        newRequest.addTempCookie(name: "newtemp", value: "new")
        
        Task {
            do {
                let _: Post = try await self.networkService.start(baseRequest)
                let _: Post = try await self.networkService.start(newRequest)
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
        
        CookieManager.shared.saveCookiesToSession([testCookie])
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
    
    func testStartBatchSuccessAsyncAwait() {
        let expectation = XCTestExpectation(description: "Fetch batch data successfully")
        
        Task {
            do {
                let baseRequest1 = Request<Post>(url: self.getURL, method: .get)
                let baseRequest2 = Request<Post>(url: self.getURL, method: .get)
                let requests = [baseRequest1, baseRequest2]
                
                let results: [Result<Post, Error>] = try await self.networkService.startBatch(requests)
                
                for result in results {
                    switch result {
                    case .success(let post):
                        XCTAssertEqual(post.userId, 1)
                        XCTAssertEqual(post.id, 1)
                    case .failure:
                        XCTFail("One of the requests failed")
                    }
                }
                
                expectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testStartBatchFailureAsyncAwait() {
        let expectation = XCTestExpectation(description: "Fetch batch data with some failures")
        
        Task {
            do {
                let validRequest = Request<Post>(url: self.getURL, method: .get)
                let invalidRequest = Request<Post>(url: URL(string: "https://jsonplaceholder.typicode.com/invalid")!, method: .get)
                let requests = [validRequest, invalidRequest]
                
                let results: [Result<Post, Error>] = try await self.networkService.startBatch(requests)
                
                var successCount = 0
                var failureCount = 0
                
                for result in results {
                    switch result {
                    case .success(let post):
                        XCTAssertEqual(post.userId, 1)
                        XCTAssertEqual(post.id, 1)
                        successCount += 1
                    case .failure:
                        failureCount += 1
                    }
                }
                
                XCTAssertEqual(successCount, 1)
                XCTAssertEqual(failureCount, 1)
                expectation.fulfill()
            } catch {
                XCTFail("Failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testStartBatchExitEarlyOnFailureAsyncAwait() {
        let expectation = XCTestExpectation(description: "Exit early on failure")
        
        Task {
            do {
                let validRequest = Request<Post>(url: self.getURL, method: .get)
                let invalidRequest = Request<Post>(url: URL(string: "https://jsonplaceholder.typicode.com/invalid")!, method: .get)
                let requests = [validRequest, invalidRequest]
                
                _ = try await self.networkService.startBatch(requests, exitEarlyOnFailure: true)
                XCTFail("Expected to throw an error, but succeeded instead")
            } catch let error as NetworkError {
                XCTAssertNotNil(error, "Expected a NetworkError but got nil")
                expectation.fulfill()
            } catch {
                XCTFail("Expected a NetworkError but got \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testStartBatchSuccessClosure() {
        let expectation = XCTestExpectation(description: "Fetch batch data successfully")
        
        let baseRequest1 = Request<Post>(url: self.getURL, method: .get)
        let baseRequest2 = Request<Post>(url: self.getURL, method: .get)
        let requests = [baseRequest1, baseRequest2]
        
        networkService.startBatch(requests) { result in
            switch result {
            case .success(let results):
                for result in results {
                    switch result {
                    case .success(let post):
                        XCTAssertEqual(post.userId, 1)
                        XCTAssertEqual(post.id, 1)
                    case .failure:
                        XCTFail("One of the requests failed")
                    }
                }
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Batch failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testStartBatchFailureClosure() {
        let expectation = XCTestExpectation(description: "Fetch batch data with some failures")
        
        let validRequest = Request<Post>(url: self.getURL, method: .get)
        let invalidRequest = Request<Post>(url: URL(string: "https://jsonplaceholder.typicode.com/invalid")!, method: .get)
        let requests = [validRequest, invalidRequest]
        
        networkService.startBatch(requests) { result in
            switch result {
            case .success(let results):
                var successCount = 0
                var failureCount = 0
                
                for result in results {
                    switch result {
                    case .success(let post):
                        XCTAssertEqual(post.userId, 1)
                        XCTAssertEqual(post.id, 1)
                        successCount += 1
                    case .failure:
                        failureCount += 1
                    }
                }
                
                XCTAssertEqual(successCount, 1)
                XCTAssertEqual(failureCount, 1)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Batch failed with error: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testStartBatchExitEarlyOnFailureClosure() {
        let expectation = XCTestExpectation(description: "Exit early on failure")
        
        let validRequest = Request<Post>(url: self.getURL, method: .get)
        let invalidRequest = Request<Post>(url: URL(string: "https://jsonplaceholder.typicode.com/invalid")!, method: .get)
        let requests = [validRequest, invalidRequest]
        
        networkService.startBatch(requests, exitEarlyOnFailure: true) { result in
            switch result {
            case .success:
                XCTFail("Expected to throw an error, but succeeded instead")
            case .failure(let error):
                if let networkError = error as? NetworkError {
                    XCTAssertNotNil(networkError, "Expected a NetworkError but got nil")
                } else {
                    XCTFail("Expected a NetworkError but got \(error)")
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testStartBatchWithMultipleTypes() async throws {
        let postRequest = Request<Post>(
            url: getURL,
            method: .get
        )
        let postWithoutIdRequest = Request<PostWithoutId>(
            url: getURL,
            method: .get
        )
        
        let requests: [any RequestProtocol] = [postRequest, postWithoutIdRequest]
        
        let results = try await networkService.startBatchWithMultipleTypes(requests)
        
        XCTAssertEqual(results.count, 2)
        
        if case .success(let post) = results[0] {
            XCTAssertTrue(post is Post)
        } else {
            XCTFail("Expected success for first request")
        }
        
        if case .success(let postWithoutId) = results[1] {
            XCTAssertTrue(postWithoutId is PostWithoutId)
        } else {
            XCTFail("Expected success for second request")
        }
    }
}

// 'Post' for testing jsonplaceholder.typicode.com data
struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

struct PostWithoutId: Codable {
    let title: String
    let body: String
}
