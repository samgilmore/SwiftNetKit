import XCTest
@testable import SwiftNetKit

final class NetworkServiceTests: XCTestCase {
    var networkService: NetworkService!
    let getURL = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
    
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
}

// 'Post' for testing jsonplaceholder.typicode.com data
struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
