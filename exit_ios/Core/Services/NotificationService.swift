//
//  NotificationService.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import UserNotifications
import UIKit

/// 알림 권한 상태
enum NotificationAuthorizationStatus {
    case authorized
    case denied
    case notDetermined
}

/// 로컬 알림 관리 서비스
final class NotificationService {
    
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Permission
    
    /// 현재 알림 권한 상태 확인
    func checkAuthorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }
    
    /// 알림 권한이 허용되었는지 확인
    func isAuthorized() async -> Bool {
        let status = await checkAuthorizationStatus()
        return status == .authorized
    }
    
    /// 알림 권한 요청
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }
    
    /// 설정 앱으로 이동
    @MainActor
    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
    
    // MARK: - Scheduling
    
    /// 알람 스케줄링
    func scheduleReminder(_ reminder: DepositReminder) {
        let content = UNMutableNotificationContent()
        content.title = "입금 알림"
        content.body = "\(reminder.name) 입금을 기록해주세요!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        let calendar = Calendar.current
        dateComponents.hour = calendar.component(.hour, from: reminder.time)
        dateComponents.minute = calendar.component(.minute, from: reminder.time)
        
        switch reminder.repeatType {
        case .once:
            break
        case .daily:
            break
        case .weekly:
            if let dayOfWeek = reminder.dayOfWeek {
                dateComponents.weekday = dayOfWeek.rawValue
            }
        case .monthly:
            if let dayOfMonth = reminder.dayOfMonth {
                dateComponents.day = dayOfMonth
            }
        }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: reminder.repeatType != .once
        )
        
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    /// 여러 알람 스케줄링 (기존 알림 제거 후)
    func scheduleReminders(_ reminders: [DepositReminder]) {
        // 기존 알림 모두 제거
        removeAllPendingNotifications()
        
        // 활성화된 알람만 스케줄링
        for reminder in reminders where reminder.isEnabled {
            scheduleReminder(reminder)
        }
    }
    
    /// 특정 알람 취소
    func cancelReminder(_ reminder: DepositReminder) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }
    
    /// 모든 예약된 알림 취소
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

