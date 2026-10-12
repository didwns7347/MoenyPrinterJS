import Foundation

actor TokenManager {
    enum KeychainKey {
        static let service = "com.firejs.MoneyPrinter.korea-investment"
        static let accessToken = "accessToken"
        static let tokenExpiresAt = "expiresIn"
    }
    private var token: String?
    private var expiresAt: Date?
    private let http: HTTPClient
    private let secureStorage: StorageProtocol
    private var refreshingTask: Task<String, Error>? = nil

    init(
        http: HTTPClient,
        secureStorage: StorageProtocol = KeychainStorage.shared
    ) {
        self.http = http
        self.secureStorage = secureStorage
        let (token, expiresAt) = TokenManager.loadTokenFromKeychainStatic(secureStorage: secureStorage)
        self.token = token
        self.expiresAt = expiresAt
    }

    private static func loadTokenFromKeychainStatic(secureStorage: StorageProtocol) -> (String?, Date?) {
        if let tokenData = secureStorage.read(service: KeychainKey.service, account: KeychainKey.accessToken),
           let token = String(data: tokenData, encoding: .utf8),
           let expiresAtData = secureStorage.read(service: KeychainKey.service, account: KeychainKey.tokenExpiresAt),
           let expiresAt = try? JSONDecoder().decode(Date.self, from: expiresAtData) {
            return (token, expiresAt)
        }
        return (nil, nil)
    }

    func getValidToken() async throws -> String {
        let now = Date()
        if let token = token, let expires = expiresAt, expires > now {
            return token
        }
        // 이미 발급 중이면 기존 Task를 기다림
        if let task = refreshingTask {
            return try await task.value
        }
        // 새로 발급 Task 생성
        let task = Task<String, Error> {
            let request = try await KoreaInvestmentEndpoint.issueToken.makeRequest()
            let response: TokenResponse = try await http.send(request, as: TokenResponse.self)
            let newToken = response.accessToken
            let newExpiresAt = Self.expireDate(from: response.tokenExpiredAt)

            let expiresAtData = try JSONEncoder().encode(newExpiresAt)
            secureStorage.save(newToken.data(using: .utf8) ?? Data(), service: KeychainKey.service, account: KeychainKey.accessToken)
            secureStorage.save(expiresAtData, service: KeychainKey.service, account: KeychainKey.tokenExpiresAt)
            self.token = newToken
            self.expiresAt = newExpiresAt
            return newToken
        }
        refreshingTask = task
        defer { refreshingTask = nil }
        return try await task.value
    }

    private static func expireDate(from text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: text)
    }

    func resetToken() {
        self.token = nil
        self.expiresAt = nil
        secureStorage.delete(service: KeychainKey.service, account: KeychainKey.accessToken)
        secureStorage.delete(service: KeychainKey.service, account: KeychainKey.tokenExpiresAt)
    }
}
