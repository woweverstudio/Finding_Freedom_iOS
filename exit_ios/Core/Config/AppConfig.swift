//
//  AppConfig.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  앱 설정 관리 (API Key 등)
//

import Foundation

/// 앱 설정 관리
enum AppConfig {
    
    /// Polygon.io API Key (Info.plist에서 로드, xcconfig로 주입)
    static let polygonAPIKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "POLYGON_API_KEY") as? String,
              !key.isEmpty else {
            fatalError("POLYGON_API_KEY가 설정되지 않았습니다. Config.xcconfig 파일을 확인하세요.")
        }
        return key
    }()
}
