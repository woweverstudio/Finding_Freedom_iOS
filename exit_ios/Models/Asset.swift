//
//  Asset.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData

/// 앱 전체에서 단일로 관리되는 현재 자산
/// 모든 시나리오가 이 값을 참조합니다.
@Model
final class Asset {
    /// 고유 ID
    var id: UUID = UUID()
    
    /// 현재 총 순자산 (원 단위)
    var amount: Double = 0
    
    /// 보유 자산 종류
    var assetTypes: [String] = []
    
    /// 생성일
    var createdAt: Date = Date()
    
    /// 마지막 업데이트일
    var updatedAt: Date = Date()
    
    init() {}
    
    init(amount: Double, assetTypes: [String] = []) {
        self.id = UUID()
        self.amount = amount
        self.assetTypes = assetTypes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// 자산 업데이트
    func update(amount: Double, assetTypes: [String]? = nil) {
        self.amount = amount
        if let types = assetTypes {
            self.assetTypes = types
        }
        self.updatedAt = Date()
    }
}

