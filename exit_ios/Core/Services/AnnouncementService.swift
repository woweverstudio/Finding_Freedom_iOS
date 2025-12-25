//
//  AnnouncementService.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation

/// 공지사항 서비스 (JSON 로드 + 읽음 상태 관리)
final class AnnouncementService {
    
    // MARK: - Singleton
    
    static let shared = AnnouncementService()
    
    private init() {
        // 초기화 시 캐시 로드
        loadCache()
    }
    
    // MARK: - Keys
    
    private let readAnnouncementsKey = "readAnnouncementIds"
    
    // MARK: - Cache
    
    /// 캐시된 공지사항 (앱 실행 중 재사용)
    private var cachedAnnouncements: [Announcement]?
    
    /// 캐시된 읽음 ID
    private var cachedReadIds: Set<String> = []
    
    // MARK: - Public Methods
    
    /// 공지사항 로드 (캐시 우선)
    func loadAnnouncements() -> [Announcement] {
        // 캐시가 있으면 캐시 반환 (읽음 상태만 업데이트)
        if var cached = cachedAnnouncements {
            // 읽음 상태 업데이트
            for i in 0..<cached.count {
                cached[i].isRead = cachedReadIds.contains(cached[i].id)
            }
            return cached
        }
        
        // 캐시가 없으면 JSON에서 로드
        return loadFromJSON()
    }
    
    /// JSON에서 강제 새로고침
    func refreshAnnouncements() -> [Announcement] {
        cachedAnnouncements = nil
        return loadFromJSON()
    }
    
    /// 공지사항 읽음 처리
    func markAsRead(_ announcement: Announcement) {
        if !cachedReadIds.contains(announcement.id) {
            cachedReadIds.insert(announcement.id)
            saveReadAnnouncementIds(cachedReadIds)
        }
    }
    
    /// 읽지 않은 공지사항 수
    func unreadCount(for announcements: [Announcement]) -> Int {
        return announcements.filter { !cachedReadIds.contains($0.id) }.count
    }
    
    /// 모든 읽음 상태 초기화
    func resetReadStatus() {
        cachedReadIds.removeAll()
        UserDefaults.standard.removeObject(forKey: readAnnouncementsKey)
    }
    
    // MARK: - Private Methods
    
    private func loadCache() {
        cachedReadIds = getReadAnnouncementIds()
    }
    
    private func loadFromJSON() -> [Announcement] {
        guard let url = Bundle.main.url(forResource: "announcements", withExtension: "json") else {
            print("announcements.json 파일을 찾을 수 없습니다.")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let announcementsData = try decoder.decode(AnnouncementsData.self, from: data)
            var announcements = announcementsData.announcements
            
            // 읽음 상태 적용
            for i in 0..<announcements.count {
                announcements[i].isRead = cachedReadIds.contains(announcements[i].id)
            }
            
            // 최신순 정렬
            let sorted = announcements.sorted { $0.publishedAt > $1.publishedAt }
            
            // 캐시에 저장
            cachedAnnouncements = sorted
            
            return sorted
            
        } catch {
            print("공지사항 로드 오류: \(error)")
            return []
        }
    }
    
    private func getReadAnnouncementIds() -> Set<String> {
        let ids = UserDefaults.standard.stringArray(forKey: readAnnouncementsKey) ?? []
        return Set(ids)
    }
    
    private func saveReadAnnouncementIds(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids), forKey: readAnnouncementsKey)
    }
}
