//
//  ReviewService.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import StoreKit

/// 앱 리뷰 요청 서비스
/// Apple의 SKStoreReviewController를 래핑하여 적절한 시점에 리뷰 요청 팝업을 표시
@MainActor
final class ReviewService {
    
    // MARK: - Singleton
    
    static let shared = ReviewService()
    
    private init() {}
    
    // MARK: - UserDefaults Keys
    
    private enum UserDefaultsKey {
        static let appLaunchCount = "ReviewService.appLaunchCount"
        static let simulationRunCount = "ReviewService.simulationRunCount"
        static let hasShownReview = "ReviewService.hasShownReview"
    }
    
    // MARK: - State
    
    /// 이번 세션에서 리뷰 요청 여부 (메모리에만 저장)
    private var hasRequestedReviewThisSession = false
    
    // MARK: - Public Methods
    
    /// 앱 실행 시 호출
    /// 3번째 실행 시 리뷰 요청
    func recordAppLaunch() {
        // 세션 플래그 초기화
        hasRequestedReviewThisSession = false
        
        // 이미 리뷰를 표시한 적 있으면 스킵
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: UserDefaultsKey.hasShownReview) else {
            return
        }
        
        // 실행 횟수 증가
        let launchCount = defaults.integer(forKey: UserDefaultsKey.appLaunchCount) + 1
        defaults.set(launchCount, forKey: UserDefaultsKey.appLaunchCount)
        
        #if DEBUG
        print("📝 ReviewService: 앱 실행 횟수 = \(launchCount)")
        #endif
        
        // 3번째 실행 시 리뷰 요청
        if launchCount == 3 {
            requestReview(reason: "앱 3회 실행")
        }
    }
    
    /// 시뮬레이션 완료 시 호출
    /// 구매 후 2번째 시뮬레이션 완료 시 리뷰 요청
    func recordSimulationCompleted() {
        // 이미 리뷰를 표시한 적 있으면 스킵
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: UserDefaultsKey.hasShownReview) else {
            return
        }
        
        // 시뮬레이션 실행 횟수 증가
        let runCount = defaults.integer(forKey: UserDefaultsKey.simulationRunCount) + 1
        defaults.set(runCount, forKey: UserDefaultsKey.simulationRunCount)
        
        #if DEBUG
        print("📝 ReviewService: 시뮬레이션 실행 횟수 = \(runCount)")
        #endif
        
        // 2번째 시뮬레이션 완료 시 리뷰 요청
        if runCount == 2 {
            requestReview(reason: "시뮬레이션 2회 실행")
        }
    }
    
    // MARK: - Private Methods
    
    /// 리뷰 요청 실행
    private func requestReview(reason: String) {
        // 이번 세션에서 이미 요청했으면 스킵
        guard !hasRequestedReviewThisSession else { return }
        
        #if DEBUG
        print("📝 ReviewService: 리뷰 요청 (사유: \(reason))")
        #endif
        
        hasRequestedReviewThisSession = true
        UserDefaults.standard.set(true, forKey: UserDefaultsKey.hasShownReview)
        
        // 약간의 딜레이 후 리뷰 요청
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
            
            guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                return
            }
            
            // iOS 18+ 새로운 API 사용
            if #available(iOS 18.0, *) {
                AppStore.requestReview(in: scene)
            } else {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}
