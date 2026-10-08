import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct HTTPRequest {
    var method: HTTPMethod
    var path: String
    var query: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?

    init(
        method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.headers = headers
        self.body = body
    }
}

struct HTTPResponse {
    let data: Data
    let response: HTTPURLResponse

    var statusCode: Int { response.statusCode }

    func header(_ name: String) -> String? {
        response.value(forHTTPHeaderField: name)
    }
}

struct RetryPolicy {
    var maxRetries: Int
    var retryableStatusCodes: Set<Int>
    var baseDelay: TimeInterval
    var maxDelay: TimeInterval

    static let none = RetryPolicy(maxRetries: 0)

    init(
        maxRetries: Int = 3,
        retryableStatusCodes: Set<Int> = [429, 503],
        baseDelay: TimeInterval = 0.5,
        maxDelay: TimeInterval = 8
    ) {
        self.maxRetries = maxRetries
        self.retryableStatusCodes = retryableStatusCodes
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }
}
