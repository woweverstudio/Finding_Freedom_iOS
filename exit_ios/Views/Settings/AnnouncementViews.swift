//
//  AnnouncementViews.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

// MARK: - Announcement List View

struct AnnouncementListView: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Exit.background
                    .ignoresSafeArea()
                
                if viewModel.announcements.isEmpty {
                    emptyState
                } else {
                    announcementList
                }
            }
            .navigationTitle("공지사항")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(Color.Exit.secondaryText)
                }
            }
            .navigationDestination(for: Announcement.self) { announcement in
                AnnouncementDetailContent(announcement: announcement)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private var emptyState: some View {
        VStack(spacing: ExitSpacing.md) {
            Image(systemName: "megaphone")
                .font(.system(size: 48))
                .foregroundStyle(Color.Exit.tertiaryText)
            
            Text("공지사항이 없습니다")
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
    
    private var announcementList: some View {
        ScrollView {
            LazyVStack(spacing: ExitSpacing.sm) {
                ForEach(viewModel.announcements, id: \.id) { announcement in
                    announcementRow(announcement)
                }
            }
            .padding(ExitSpacing.md)
        }
    }
    
    private func announcementRow(_ announcement: Announcement) -> some View {
        NavigationLink(value: announcement) {
            HStack(spacing: ExitSpacing.md) {
                // 타입 아이콘
                ZStack {
                    Circle()
                        .fill(Color(hex: announcement.type.color).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: announcement.type.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: announcement.type.color))
                }
                
                // 내용
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    HStack(spacing: ExitSpacing.xs) {
                        // 타입 뱃지
                        Text(announcement.type.rawValue)
                            .font(.Exit.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(hex: announcement.type.color))
                            .padding(.horizontal, ExitSpacing.sm)
                            .padding(.vertical, 2)
                            .background(Color(hex: announcement.type.color).opacity(0.15))
                            .clipShape(Capsule())
                        
                        // 중요 표시
                        if announcement.isImportant {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.Exit.caution)
                        }
                        
                        Spacer()
                        
                        // 날짜
                        Text(announcement.relativeTimeText)
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                    
                    // 제목
                    Text(announcement.title)
                        .font(.Exit.body)
                        .fontWeight(announcement.isRead ? .regular : .semibold)
                        .foregroundStyle(announcement.isRead ? Color.Exit.secondaryText : Color.Exit.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                // 읽지 않음 인디케이터
                if !announcement.isRead {
                    Circle()
                        .fill(Color.Exit.accent)
                        .frame(width: 8, height: 8)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            viewModel.markAsRead(announcement)
        })
    }
}

// MARK: - Announcement Detail Content (Navigation 내부용)

struct AnnouncementDetailContent: View {
    let announcement: Announcement
    
    var body: some View {
        ZStack {
            Color.Exit.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: ExitSpacing.lg) {
                    // 헤더
                    headerSection
                    
                    // 구분선
                    Divider()
                        .background(Color.Exit.divider)
                    
                    // 본문
                    contentSection
                }
                .padding(ExitSpacing.lg)
            }
        }
        .navigationTitle("공지사항")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            // 타입 및 날짜
            HStack {
                // 타입 뱃지
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: announcement.type.icon)
                        .font(.system(size: 12))
                    Text(announcement.type.rawValue)
                        .font(.Exit.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color(hex: announcement.type.color))
                .padding(.horizontal, ExitSpacing.sm)
                .padding(.vertical, ExitSpacing.xs)
                .background(Color(hex: announcement.type.color).opacity(0.15))
                .clipShape(Capsule())
                
                if announcement.isImportant {
                    HStack(spacing: ExitSpacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("중요")
                            .font(.Exit.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.Exit.caution)
                }
                
                Spacer()
                
                Text(announcement.publishedDateText)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            // 제목
            Text(announcement.title)
                .font(.Exit.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
    
    private var contentSection: some View {
        Text(announcement.content)
            .font(.Exit.body)
            .foregroundStyle(Color.Exit.secondaryText)
            .lineSpacing(6)
    }
}

// MARK: - Preview

#Preview("List") {
    AnnouncementListView(viewModel: SettingsViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Detail") {
    NavigationStack {
        AnnouncementDetailContent(
            announcement: Announcement(
                title: "Exit 앱에 오신 것을 환영합니다! 🎉",
                content: """
                Exit 앱을 설치해 주셔서 감사합니다.
                
                Exit은 여러분의 조기 은퇴를 도와드리는 자산 관리 앱입니다.
                
                매월 입금을 기록하고, 다양한 시나리오를 통해 은퇴까지 남은 시간을 확인해보세요.
                """,
                type: .notice,
                isImportant: true
            )
        )
    }
    .preferredColorScheme(.dark)
}

