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

@Observable
final class SettingsViewModel {
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    private let announcementService = AnnouncementService.shared
    private let notificationService = NotificationService.shared
    
    // MARK: - Configuration State
    
    private var isConfigured = false
    
    // MARK: - State
    
    /// 입금 알람 목록
    var depositReminders: [DepositReminder] = []
    
    /// 공지사항 목록
    var announcements: [Announcement] = []
    
    /// 마퀴에 표시할 중요 공지사항
    var marqueeAnnouncements: [Announcement] {
        announcements.filter { $0.isImportant }
    }
    
    /// 읽지 않은 공지사항 수
    var unreadCount: Int {
        announcements.filter { !$0.isRead }.count
    }
    
    /// 알림 권한 활성화 상태
    var isNotificationEnabled: Bool = false
    
    // MARK: - Sheet States
    
    var showReminderSheet: Bool = false
    var editingReminder: DepositReminder?
    var showAnnouncementList: Bool = false
    var selectedAnnouncement: Announcement?
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
        guard !isConfigured else { return }
        
        self.modelContext = context
        isConfigured = true
        
        announcements = announcementService.loadAnnouncements()
        loadReminders()
        checkNotificationPermissionStatus()
    }
    
    // MARK: - Data Loading
    
    private func loadReminders() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<DepositReminder>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        depositReminders = (try? context.fetch(descriptor)) ?? []
    }
    
    func refreshData() {
        loadReminders()
        announcements = announcementService.loadAnnouncements()
    }
    
    // MARK: - Notification Permission
    
    func checkNotificationPermissionStatus() {
        Task { @MainActor in
            let wasEnabled = isNotificationEnabled
            isNotificationEnabled = await notificationService.isAuthorized()
            
            if wasEnabled && !isNotificationEnabled {
                disableAllReminders()
            } else if isNotificationEnabled {
                notificationService.scheduleReminders(depositReminders)
            }
        }
    }
    
    func toggleNotificationPermission() {
        Task { @MainActor in
            let status = await notificationService.checkAuthorizationStatus()
            
            switch status {
            case .notDetermined:
                let granted = await notificationService.requestAuthorization()
                isNotificationEnabled = granted
                if !granted {
                    disableAllReminders()
                }
            case .denied, .authorized:
                notificationService.openSettings()
            }
        }
    }
    
    // MARK: - Reminder Actions
    
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
    
    func saveReminder() {
        guard let context = modelContext, !reminderName.isEmpty else { return }
        
        if let existing = editingReminder {
            existing.name = reminderName
            existing.repeatType = reminderRepeatType
            existing.dayOfMonth = reminderRepeatType == .monthly ? reminderDayOfMonth : nil
            existing.dayOfWeek = reminderRepeatType == .weekly ? reminderDayOfWeek : nil
            existing.time = reminderTime
            existing.isEnabled = reminderIsEnabled
            existing.updatedAt = Date()
        } else {
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
        
        // 권한 확인 후 스케줄링
        Task { @MainActor in
            let isAuthorized = await notificationService.isAuthorized()
            if isAuthorized {
                notificationService.scheduleReminders(depositReminders)
            } else {
                let granted = await notificationService.requestAuthorization()
                if granted {
                    notificationService.scheduleReminders(depositReminders)
                } else {
                    disableAllReminders()
                }
            }
        }
        
        showReminderSheet = false
    }
    
    func deleteReminder(_ reminder: DepositReminder) {
        guard let context = modelContext else { return }
        
        notificationService.cancelReminder(reminder)
        context.delete(reminder)
        try? context.save()
        loadReminders()
    }
    
    func toggleReminder(_ reminder: DepositReminder) {
        guard let context = modelContext else { return }
        
        let newState = !reminder.isEnabled
        
        if newState {
            Task { @MainActor in
                let isAuthorized = await notificationService.isAuthorized()
                
                if isAuthorized {
                    reminder.isEnabled = true
                    reminder.updatedAt = Date()
                    try? context.save()
                    loadReminders()
                    notificationService.scheduleReminders(depositReminders)
                } else {
                    let granted = await notificationService.requestAuthorization()
                    if granted {
                        isNotificationEnabled = true
                        reminder.isEnabled = true
                        reminder.updatedAt = Date()
                        try? context.save()
                        loadReminders()
                        notificationService.scheduleReminders(depositReminders)
                    } else {
                        disableAllReminders()
                    }
                }
            }
        } else {
            reminder.isEnabled = false
            reminder.updatedAt = Date()
            try? context.save()
            loadReminders()
            notificationService.scheduleReminders(depositReminders)
        }
    }
    
    private func disableAllReminders() {
        guard let context = modelContext else { return }
        
        for reminder in depositReminders {
            reminder.isEnabled = false
            reminder.updatedAt = Date()
        }
        
        try? context.save()
        loadReminders()
        notificationService.removeAllPendingNotifications()
    }
    
    // MARK: - Announcement Actions
    
    func markAsRead(_ announcement: Announcement) {
        announcementService.markAsRead(announcement)
        if let index = announcements.firstIndex(where: { $0.id == announcement.id }) {
            announcements[index].isRead = true
        }
    }
    
    func selectAnnouncement(_ announcement: Announcement) {
        markAsRead(announcement)
        selectedAnnouncement = announcement
    }
    
    // MARK: - Data Management
    
    func deleteAllData() {
        guard let context = modelContext else { return }
        
        // 모든 데이터 삭제
        deleteAll(UserProfile.self, from: context)
        deleteAll(MonthlyUpdate.self, from: context)
        deleteAll(Asset.self, from: context)
        deleteAll(AssetSnapshot.self, from: context)
        deleteAll(DepositReminder.self, from: context)
        
        announcementService.resetReadStatus()
        notificationService.removeAllPendingNotifications()
        
        try? context.save()
    }
    
    private func deleteAll<T: PersistentModel>(_ type: T.Type, from context: ModelContext) {
        let descriptor = FetchDescriptor<T>()
        if let items = try? context.fetch(descriptor) {
            for item in items {
                context.delete(item)
            }
        }
    }
}
