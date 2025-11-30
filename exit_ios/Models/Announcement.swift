//
//  Announcement.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation

/// 공지사항 타입
enum AnnouncementType: String, Codable, CaseIterable {
    case notice = "공지"
    case update = "업데이트"
    case event = "이벤트"
    case tip = "꿀팁"
    
    var icon: String {
        switch self {
        case .notice: return "megaphone.fill"
        case .update: return "sparkles"
        case .event: return "gift.fill"
        case .tip: return "lightbulb.fill"
        }
    }
    
    var color: String {
        switch self {
        case .notice: return "00D4AA"
        case .update: return "00B894"
        case .event: return "FF9500"
        case .tip: return "34C759"
        }
    }
}

/// 공지사항 모델 (JSON에서 로드)
struct Announcement: Codable, Identifiable, Hashable {
    /// 고유 식별자
    let id: String
    
    /// 공지사항 제목
    let title: String
    
    /// 공지사항 내용
    let content: String
    
    /// 공지사항 타입
    let type: AnnouncementType
    
    /// 중요 공지 여부
    let isImportant: Bool
    
    /// 게시일 (ISO8601 형식)
    let publishedAt: Date
    
    /// 버전 (선택적 - 업데이트 공지용)
    let version: String?
    
    /// 링크 URL (선택적)
    let linkURL: String?
    
    /// 읽음 여부 (런타임에서 관리)
    var isRead: Bool = false
    
    // MARK: - Initializer
    
    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        type: AnnouncementType = .notice,
        isImportant: Bool = false,
        publishedAt: Date = Date(),
        version: String? = nil,
        linkURL: String? = nil,
        isRead: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.type = type
        self.isImportant = isImportant
        self.publishedAt = publishedAt
        self.version = version
        self.linkURL = linkURL
        self.isRead = isRead
    }
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case type
        case isImportant
        case publishedAt
        case version
        case linkURL
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Announcement, rhs: Announcement) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Computed Properties
    
    /// 게시일 표시 텍스트
    var publishedDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: publishedAt)
    }
    
    /// 상대 시간 텍스트 (예: "3일 전")
    var relativeTimeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: publishedAt, relativeTo: Date())
    }
}

/// 공지사항 JSON 루트 구조
struct AnnouncementsData: Codable {
    let announcements: [Announcement]
}
