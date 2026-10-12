import Foundation

enum APIConfigError: LocalizedError {
    case missingKeys([String])
    case invalidBaseURL(String)

    var errorDescription: String? {
        switch self {
        case .missingKeys(let keys):
            return "한국투자증권 설정이 없습니다: \(keys.joined(separator: ", ")). Config.xcconfig에 넣은 뒤 앱을 다시 빌드하세요."
        case .invalidBaseURL(let value):
            return "URL_BASE가 올바른 주소가 아닙니다: \(value)"
        }
    }
}

/// Info.plist에서 한국투자증권 API 관련 키를 로드합니다.
struct APIConfigManager {
    /// 모의투자 서버를 쓰려면 true로 바꾸고 URL_BASE도 모의투자 주소로 맞춥니다.
    static let isDemo = false

    let appKey: String
    let appSecret: String
    let baseURL: String
    let cano: String
    let accountCode: String

    private static let keys = ["APP_KEY", "APP_SECRET", "URL_BASE", "CANO", "ACNT_PRDT_CD"]
    private static var cached: APIConfigManager?

    static func load() throws -> APIConfigManager {
        if let cached { return cached }
        let values = try read()
        let config = APIConfigManager(
            appKey: values["APP_KEY"] ?? "",
            appSecret: values["APP_SECRET"] ?? "",
            baseURL: "https://\(values["URL_BASE"] ?? "")",
            cano: values["CANO"] ?? "",
            accountCode: values["ACNT_PRDT_CD"] ?? ""
        )
        cached = config
        return config
    }

    private static func read() throws -> [String: String] {
        var resolved: [String: String] = [:]
        var missing: [String] = []
        for key in keys {
            let raw = (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if raw.isEmpty || raw.hasPrefix("$(") {
                missing.append(key)
            } else {
                resolved[key] = raw
            }
        }
        guard missing.isEmpty else { throw APIConfigError.missingKeys(missing) }
        return resolved
    }
}
