//
//  AnnouncementListView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  공지사항 목록 뷰
//

import SwiftUI

/// 공지사항 목록 뷰
struct AnnouncementListView: View {
    @Bindable var viewModel: MenuViewModel
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
                AnnouncementDetailView(announcement: announcement)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    private var emptyState: some View {
        VStack(spacing: ExitSpacing.md) {
            Text("공지사항이 없습니다")
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.tertiaryText)
        }
    }
    
    private var announcementList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.announcements, id: \.id) { announcement in
                    announcementRow(announcement)
                    
                    if announcement.id != viewModel.announcements.last?.id {
                        Divider()
                            .background(Color.Exit.divider)
                            .padding(.leading, ExitSpacing.md)
                    }
                }
            }
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            .padding(ExitSpacing.md)
        }
    }
    
    private func announcementRow(_ announcement: Announcement) -> some View {
        NavigationLink(value: announcement) {
            HStack(spacing: ExitSpacing.md) {
                // 내용
                VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                    // 제목
                    Text(announcement.title)
                        .font(.Exit.body)
                        .fontWeight(announcement.isRead ? .regular : .medium)
                        .foregroundStyle(announcement.isRead ? Color.Exit.secondaryText : Color.Exit.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // 날짜
                    Text(announcement.relativeTimeText)
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                
                Spacer()
                
                // 읽지 않음 인디케이터
                if !announcement.isRead {
                    Circle()
                        .fill(Color.Exit.accent)
                        .frame(width: 6, height: 6)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            .padding(ExitSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            viewModel.markAsRead(announcement)
        })
    }
}

// MARK: - Preview

#Preview {
    AnnouncementListView(viewModel: MenuViewModel())
        .preferredColorScheme(.dark)
}

