import Foundation

enum NetworkError: LocalizedError {
    case invalidURL(String)
    case transport(URLError)
    case http(status: Int, message: String, requestID: String?)
    case encoding(String)
    case decoding(String)
    case invalidResponse(String)

    var statusCode: Int? {
        if case .http(let status, _, _) = self {
            return status
        }
        return nil
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL(let path):
            return "잘못된 URL입니다: \(path)"
        case .transport(let error):
            return error.localizedDescription
        case .http(let status, let message, let requestID):
            if let requestID {
                return "요청 실패 (\(status)): \(message) (request_id=\(requestID))"
            }
            return "요청 실패 (\(status)): \(message)"
        case .encoding(let message):
            return "요청 본문을 만들지 못했습니다: \(message)"
        case .decoding(let message):
            return "응답을 해석하지 못했습니다: \(message)"
        case .invalidResponse(let message):
            return message
        }
    }
}
