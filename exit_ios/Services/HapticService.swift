//
//  HapticService.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import UIKit

/// 햅틱 피드백 서비스
final class HapticService {
    
    // MARK: - Singleton
    
    static let shared = HapticService()
    
    private init() {
        prepareGenerators()
    }
    
    // MARK: - Generators
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Prepare
    
    /// 제너레이터 사전 준비 (지연 시간 최소화)
    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        softGenerator.prepare()
        rigidGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Impact Feedback
    
    /// Light 햅틱 (가벼운 탭)
    func light() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }
    
    /// Medium 햅틱 (중간 탭)
    func medium() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }
    
    /// Heavy 햅틱 (강한 탭)
    func heavy() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }
    
    /// Soft 햅틱 (부드러운 탭 - 키패드용)
    func soft() {
        softGenerator.impactOccurred()
        softGenerator.prepare()
    }
    
    /// Rigid 햅틱 (딱딱한 탭)
    func rigid() {
        rigidGenerator.impactOccurred()
        rigidGenerator.prepare()
    }
    
    // MARK: - Selection Feedback
    
    /// 선택 변경 햅틱 (피커, 스위치 등)
    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    // MARK: - Notification Feedback
    
    /// 성공 햅틱
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    /// 경고 햅틱
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    /// 에러 햅틱
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
}

