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
    
    func testGetSuccess() async throws {
        do {
            let post: Post = try await networkService.get(from: getURL, decodeTo: Post.self)
            XCTAssertEqual(post.id, 1)
        } catch {
            XCTFail("Should succeed, but failed with error: \(error)")
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
