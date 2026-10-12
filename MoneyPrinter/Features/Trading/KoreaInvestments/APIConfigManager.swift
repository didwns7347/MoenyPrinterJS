//
//  APIKeyManager.swift
//  JSMacroChart
//
//  Created by yangjs on 7/15/25.
//
import Foundation
// MARK: - API Key Manager

/// Info.plist에서 한국투자증권 API 관련 키를 로드하고 관리하는 구조체
struct APIConfigManager {
    static let shared = APIConfigManager()

    let appKey: String
    let appSecret: String
    let baseURL: String
    let cano: String // 계좌번호 앞 8자리
    let accountCode: String // 계좌번호 뒤 2자리
    let isDemo: Bool = false

    private init() {
        guard let appKey = Bundle.main.object(forInfoDictionaryKey: "APP_KEY") as? String,
              let appSecret = Bundle.main.object(forInfoDictionaryKey: "APP_SECRET") as? String,
              let baseURL = Bundle.main.object(forInfoDictionaryKey: "URL_BASE") as? String,
              let cano = Bundle.main.object(forInfoDictionaryKey: "CANO") as? String,
              let accountCode = Bundle.main.object(forInfoDictionaryKey: "ACNT_PRDT_CD") as? String
        else {
            fatalError("API 키가 Info.plist에 설정되지 않았습니다.")
        }
        self.appKey = appKey
        self.appSecret = appSecret
        self.baseURL = "https://\(baseURL)"
        self.cano = cano
        self.accountCode = accountCode
    }
}

