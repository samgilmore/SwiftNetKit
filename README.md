# SwiftNetKit

SwiftNetKit is a simple and powerful network layer for making API calls in Swift. It supports various HTTP methods, handles cookies, and allows for customizable caching and retries.

## Features

- Supports HTTP GET, POST, PUT, DELETE, and PATCH methods.
- Customizable URLSession configurations.
- Cookie management.
- Custom caching configurations.
- Automatic retries for failed requests.
- Codable support for JSON parsing.
- Batch requests.

## Installation

### Swift Package Manager

To integrate SwiftNetKit into your project using Swift Package Manager, add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/samgilmore/SwiftNetKit.git", from: "1.0.0")
]
```

## Usage

### Creating a Network Request

First, create a request conforming to `RequestProtocol`. This protocol requires defining the URL, HTTP method, headers, parameters, and other configurations for the request.

```swift
struct MyRequest: RequestProtocol {
    typealias Response = MyResponseModel
    
    var url: URL { return URL(string: "https://api.example.com/data")! }
    var method: MethodType { return .get }
    var parameters: [String: Any]? { return nil }
    var headers: [String: String]? { return ["Content-Type": "application/json"] }
    var body: RequestBody? { return nil }
    var cacheConfiguration: CacheConfiguration? { return nil }
    var includeCookies: Bool { return true }
    var saveResponseCookies: Bool { return true }
    var responseType: MyResponseModel.Type { return MyResponseModel.self }
    
    func buildURLRequest() -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}
```

### Making a Network Call

Create an instance of `NetworkService` and use it to start your request.

```swift
let networkService = NetworkService()

let request = MyRequest()

networkService.start(request) { result in
    switch result {
    case .success(let responseModel):
        print("Success: \(responseModel)")
    case .failure(let error):
        print("Failure: \(error)")
    }
}
```

Or, for async/await support, you can call `start` with `async`:

```swift
Task {
    do {
        let response: MyResponseModel = try await networkService.start(request)
        print("Success: \(response)")
    } catch {
        print("Failure: \(error)")
    }
}
```

### Batch Requests

SwiftNetKit supports batch requests, allowing multiple requests to be made concurrently.

```swift
let requests: [MyRequest] = [request1, request2, request3]

Task {
    do {
        let results = try await networkService.startBatch(requests)
        for result in results {
            switch result {
            case .success(let response):
                print("Success: \(response)")
            case .failure(let error):
                print("Failure: \(error)")
            }
        }
    } catch {
        print("Batch request failed: \(error)")
    }
}
```

## Customization

### Session Configuration

Customize the URLSession configuration when initializing `NetworkService`.

```swift
let customConfiguration = SessionConfiguration.background("com.example.background")
let networkService = NetworkService(configuration: customConfiguration)
```

### Cookie Management

Enable or disable cookie management for individual requests using the `includeCookies` and `saveResponseCookies` properties.

```swift
struct MyRequest: RequestProtocol {
    // other properties
    
    var includeCookies: Bool { return true }
    var saveResponseCookies: Bool { return true }
}
```

### Cache Configuration

Customize caching behavior by implementing the `CacheConfiguration` property in your request. This allows you to define cache policies, expiration times, and other cache-related settings.

```swift
struct MyRequest: RequestProtocol {
    // other properties
    
    var cacheConfiguration: CacheConfiguration? {
        return CacheConfiguration(policy: .returnCacheDataElseLoad, expiration: .days(1))
    }
}
```

## License

SwiftNetKit is released under the MIT license. See LICENSE for details.

## Contributing

Feel free to open issues or submit pull requests for any improvements or bug fixes.

## Contact

For any questions or inquiries, please contact Sam Gilmore at [samgilmore02@gmail.com].
