//
//  DepositReminder.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import SwiftData

/// 반복 유형
enum RepeatType: String, Codable, CaseIterable {
    case once = "한 번만"
    case daily = "매일"
    case weekly = "매주"
    case monthly = "매월"
    
    var icon: String {
        switch self {
        case .once: return "1.circle"
        case .daily: return "calendar.day.timeline.left"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        }
    }
}

/// 요일 (주간 반복용)
enum Weekday: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var name: String {
        switch self {
        case .sunday: return "일"
        case .monday: return "월"
        case .tuesday: return "화"
        case .wednesday: return "수"
        case .thursday: return "목"
        case .friday: return "금"
        case .saturday: return "토"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "일요일"
        case .monday: return "월요일"
        case .tuesday: return "화요일"
        case .wednesday: return "수요일"
        case .thursday: return "목요일"
        case .friday: return "금요일"
        case .saturday: return "토요일"
        }
    }
}

/// 입금 알람 모델
@Model
final class DepositReminder {
    /// 고유 식별자
    var id: UUID
    
    /// 알람 이름 (예: "월급", "배당금")
    var name: String
    
    /// 반복 유형
    var repeatTypeRaw: String
    
    /// 월간 반복 시 날짜 (1~31)
    var dayOfMonth: Int?
    
    /// 주간 반복 시 요일 (1=일, 2=월, ..., 7=토)
    var dayOfWeekRaw: Int?
    
    /// 알람 시간
    var time: Date
    
    /// 활성화 여부
    var isEnabled: Bool
    
    /// 생성일
    var createdAt: Date
    
    /// 수정일
    var updatedAt: Date
    
    /// 반복 유형 (computed)
    var repeatType: RepeatType {
        get { RepeatType(rawValue: repeatTypeRaw) ?? .monthly }
        set { repeatTypeRaw = newValue.rawValue }
    }
    
    /// 요일 (computed)
    var dayOfWeek: Weekday? {
        get {
            guard let raw = dayOfWeekRaw else { return nil }
            return Weekday(rawValue: raw)
        }
        set { dayOfWeekRaw = newValue?.rawValue }
    }
    
    init(
        name: String,
        repeatType: RepeatType = .monthly,
        dayOfMonth: Int? = nil,
        dayOfWeek: Weekday? = nil,
        time: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.repeatTypeRaw = repeatType.rawValue
        self.dayOfMonth = dayOfMonth
        self.dayOfWeekRaw = dayOfWeek?.rawValue
        self.time = time
        self.isEnabled = isEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// 알람 설명 텍스트
    var descriptionText: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "a h:mm"
        timeFormatter.locale = Locale(identifier: "ko_KR")
        let timeString = timeFormatter.string(from: time)
        
        switch repeatType {
        case .once:
            return "\(timeString)"
        case .daily:
            return "매일 \(timeString)"
        case .weekly:
            if let day = dayOfWeek {
                return "매주 \(day.fullName) \(timeString)"
            }
            return "매주 \(timeString)"
        case .monthly:
            if let day = dayOfMonth {
                return "매월 \(day)일 \(timeString)"
            }
            return "매월 \(timeString)"
        }
    }
}

