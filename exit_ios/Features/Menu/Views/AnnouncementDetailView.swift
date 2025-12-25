//
//  AnnouncementDetailView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  공지사항 상세 뷰
//

import SwiftUI

/// 공지사항 상세 뷰 (Navigation 내부용)
struct AnnouncementDetailView: View {
    let announcement: Announcement
    
    var body: some View {
        ZStack {
            Color.Exit.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: ExitSpacing.lg) {
                    // 헤더
                    headerSection
                    
                    // 본문
                    contentSection
                }
                .padding(ExitSpacing.lg)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            // 날짜
            Text(announcement.publishedDateText)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.tertiaryText)
            
            // 제목
            Text(announcement.title)
                .font(.Exit.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
    
    private var contentSection: some View {
        Text(announcement.content)
            .font(.Exit.subheadline)
            .foregroundStyle(Color.Exit.secondaryText)
            .lineSpacing(8)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AnnouncementDetailView(
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

