//
//  SettingsViewModel.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData
import Observation
import SwiftUI
import UserNotifications

@Observable
final class SettingsViewModel {
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    private let announcementService = AnnouncementService.shared
    
    // MARK: - Configuration State
    
    /// 이미 설정되었는지 여부
    private var isConfigured = false
    
    // MARK: - State
    
    /// 입금 알람 목록
    var depositReminders: [DepositReminder] = []
    
    /// 공지사항 목록 (JSON에서 로드)
    var announcements: [Announcement] = []
    
    /// 마퀴에 표시할 중요 공지사항
    var marqueeAnnouncements: [Announcement] {
        announcements.filter { $0.isImportant }
    }
    
    /// 읽지 않은 공지사항 수
    var unreadCount: Int {
        announcements.filter { !$0.isRead }.count
    }
    
    // MARK: - Sheet States
    
    /// 알람 추가/수정 시트 표시
    var showReminderSheet: Bool = false
    
    /// 수정 중인 알람 (nil이면 새로 추가)
    var editingReminder: DepositReminder?
    
    /// 공지사항 리스트 표시
    var showAnnouncementList: Bool = false
    
    /// 선택된 공지사항 (상세 보기용)
    var selectedAnnouncement: Announcement?
    
    /// 데이터 삭제 확인 얼럿 표시
    var showDeleteConfirm: Bool = false
    
    // MARK: - Reminder Input States
    
    var reminderName: String = ""
    var reminderRepeatType: RepeatType = .monthly
    var reminderDayOfMonth: Int = 1
    var reminderDayOfWeek: Weekday = .monday
    var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var reminderIsEnabled: Bool = true
    
    // MARK: - Initialization
    
    func configure(with context: ModelContext) {
        // 이미 설정된 경우 스킵
        guard !isConfigured else { return }
        
        self.modelContext = context
        isConfigured = true
        
        // 공지사항은 캐시에서 바로 로드 (빠름)
        announcements = announcementService.loadAnnouncements()
        
        // 알람 로드
        loadReminders()
        
        // 알림 권한 요청 (비동기)
        requestNotificationPermission()
    }
    
    // MARK: - Data Loading
    
    /// 알람만 로드
    private func loadReminders() {
        guard let context = modelContext else { return }
        
        let reminderDescriptor = FetchDescriptor<DepositReminder>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        depositReminders = (try? context.fetch(reminderDescriptor)) ?? []
    }
    
    /// 전체 데이터 새로고침
    func refreshData() {
        loadReminders()
        announcements = announcementService.loadAnnouncements()
    }
    
    // MARK: - Notification Permission
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - Reminder Actions
    
    /// 알람 추가 시트 열기
    func openAddReminderSheet() {
        editingReminder = nil
        reminderName = ""
        reminderRepeatType = .monthly
        reminderDayOfMonth = Calendar.current.component(.day, from: Date())
        reminderDayOfWeek = Weekday(rawValue: Calendar.current.component(.weekday, from: Date())) ?? .monday
        reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
        reminderIsEnabled = true
        showReminderSheet = true
    }
    
    /// 알람 수정 시트 열기
    func openEditReminderSheet(_ reminder: DepositReminder) {
        editingReminder = reminder
        reminderName = reminder.name
        reminderRepeatType = reminder.repeatType
        reminderDayOfMonth = reminder.dayOfMonth ?? 1
        reminderDayOfWeek = reminder.dayOfWeek ?? .monday
        reminderTime = reminder.time
        reminderIsEnabled = reminder.isEnabled
        showReminderSheet = true
    }
    
    /// 알람 저장
    func saveReminder() {
        guard let context = modelContext, !reminderName.isEmpty else { return }
        
        if let existing = editingReminder {
            // 기존 알람 수정
            existing.name = reminderName
            existing.repeatType = reminderRepeatType
            existing.dayOfMonth = reminderRepeatType == .monthly ? reminderDayOfMonth : nil
            existing.dayOfWeek = reminderRepeatType == .weekly ? reminderDayOfWeek : nil
            existing.time = reminderTime
            existing.isEnabled = reminderIsEnabled
            existing.updatedAt = Date()
        } else {
            // 새 알람 생성
            let newReminder = DepositReminder(
                name: reminderName,
                repeatType: reminderRepeatType,
                dayOfMonth: reminderRepeatType == .monthly ? reminderDayOfMonth : nil,
                dayOfWeek: reminderRepeatType == .weekly ? reminderDayOfWeek : nil,
                time: reminderTime,
                isEnabled: reminderIsEnabled
            )
            context.insert(newReminder)
        }
        
        try? context.save()
        loadReminders()
        
        // 알람 스케줄 업데이트
        scheduleNotifications()
        
        showReminderSheet = false
    }
    
    /// 알람 삭제
    func deleteReminder(_ reminder: DepositReminder) {
        guard let context = modelContext else { return }
        
        // 알림 취소
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        
        context.delete(reminder)
        try? context.save()
        loadReminders()
    }
    
    /// 알람 활성화 토글
    func toggleReminder(_ reminder: DepositReminder) {
        guard let context = modelContext else { return }
        
        reminder.isEnabled.toggle()
        reminder.updatedAt = Date()
        
        try? context.save()
        scheduleNotifications()
    }
    
    /// 로컬 알림 스케줄링
    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        
        // 기존 알림 모두 제거
        center.removeAllPendingNotificationRequests()
        
        for reminder in depositReminders where reminder.isEnabled {
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
                // 한 번만 (다음 발생 시)
                break
            case .daily:
                // 매일
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
            
            center.add(request) { error in
                if let error = error {
                    print("Failed to schedule notification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Announcement Actions
    
    /// 공지사항 읽음 처리
    func markAsRead(_ announcement: Announcement) {
        announcementService.markAsRead(announcement)
        // 로컬 상태도 업데이트
        if let index = announcements.firstIndex(where: { $0.id == announcement.id }) {
            announcements[index].isRead = true
        }
    }
    
    /// 공지사항 선택
    func selectAnnouncement(_ announcement: Announcement) {
        markAsRead(announcement)
        selectedAnnouncement = announcement
    }
    
    // MARK: - Data Management
    
    /// 모든 데이터 삭제
    func deleteAllData() {
        guard let context = modelContext else { return }
        
        // UserProfile 삭제
        let profileDescriptor = FetchDescriptor<UserProfile>()
        if let profiles = try? context.fetch(profileDescriptor) {
            for profile in profiles {
                context.delete(profile)
            }
        }
        
        // MonthlyUpdate 삭제
        let updateDescriptor = FetchDescriptor<MonthlyUpdate>()
        if let updates = try? context.fetch(updateDescriptor) {
            for update in updates {
                context.delete(update)
            }
        }
        
        // Asset 삭제
        let assetDescriptor = FetchDescriptor<Asset>()
        if let assets = try? context.fetch(assetDescriptor) {
            for asset in assets {
                context.delete(asset)
            }
        }
        
        // AssetSnapshot 삭제
        let snapshotDescriptor = FetchDescriptor<AssetSnapshot>()
        if let snapshots = try? context.fetch(snapshotDescriptor) {
            for snapshot in snapshots {
                context.delete(snapshot)
            }
        }
        
        // DepositReminder 삭제
        let reminderDescriptor = FetchDescriptor<DepositReminder>()
        if let reminders = try? context.fetch(reminderDescriptor) {
            for reminder in reminders {
                context.delete(reminder)
            }
        }
        
        // 공지사항 읽음 상태 초기화
        announcementService.resetReadStatus()
        
        // 알림 모두 취소
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        try? context.save()
    }
}
