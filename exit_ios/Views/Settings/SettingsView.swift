//
//  SettingsView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import SwiftData

/// 설정 화면 메인 뷰
struct SettingsView: View {
    @Environment(\.appState) private var appState
    @Bindable var viewModel: SettingsViewModel
    @Binding var shouldNavigateToWelcome: Bool
    
    var body: some View {
        ZStack {
            // 배경
            Color.Exit.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ExitSpacing.xl) {
                    // 공지사항 섹션
                    announcementSection
                    
                    // 입금 알람 섹션
                    reminderSection
                    
                    // 문의하기 섹션
                    contactSection
                    
                    // 앱 정보 섹션
                    appInfoSection
                    
                    // 데이터 관리 섹션 (맨 아래로)
                    dataManagementSection
                    
                    Spacer(minLength: ExitSpacing.xl)
                }
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.lg)
            }
        }
        .sheet(isPresented: $viewModel.showReminderSheet) {
            ReminderEditSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showAnnouncementList) {
            AnnouncementListView(viewModel: viewModel)
        }
        .alert("데이터 삭제", isPresented: $viewModel.showDeleteConfirm) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                appState.resetToHomeTab() // 탭을 홈으로 초기화
                viewModel.deleteAllData()
                shouldNavigateToWelcome = true
            }
        } message: {
            Text("모든 입금 기록, 자산 정보, 시나리오가 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.")
        }
    }
    
    // MARK: - Announcement Section
    
    private var announcementSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            sectionHeader(title: "공지사항")
            
            Button {
                viewModel.showAnnouncementList = true
            } label: {
                HStack {
                    if let latestAnnouncement = viewModel.announcements.first {
                        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                            Text(latestAnnouncement.title)
                                .font(.Exit.body)
                                .fontWeight(latestAnnouncement.isRead ? .regular : .medium)
                                .foregroundStyle(Color.Exit.primaryText)
                                .lineLimit(1)
                            
                            Text(latestAnnouncement.relativeTimeText)
                                .font(.Exit.caption)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                        
                        Spacer()
                        
                        if !latestAnnouncement.isRead {
                            Circle()
                                .fill(Color.Exit.accent)
                                .frame(width: 6, height: 6)
                        }
                    } else {
                        Text("공지사항이 없습니다")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.tertiaryText)
                        
                        Spacer()
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                .padding(ExitSpacing.md)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Reminder Section
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            HStack {
                sectionHeader(title: "알람")
                
                Spacer()
                
                Button {
                    viewModel.openAddReminderSheet()
                } label: {
                    Text("추가")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.accent)
                }
                .buttonStyle(.plain)
            }
            
            VStack(spacing: 0) {
                if viewModel.depositReminders.isEmpty {
                    // 빈 상태
                    HStack {
                        Text("등록된 알람이 없습니다")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.tertiaryText)
                        
                        Spacer()
                    }
                    .padding(ExitSpacing.md)
                } else {
                    // 알람 리스트
                    ForEach(viewModel.depositReminders, id: \.id) { reminder in
                        reminderRow(reminder)
                        
                        if reminder.id != viewModel.depositReminders.last?.id {
                            Divider()
                                .background(Color.Exit.divider)
                                .padding(.leading, ExitSpacing.md)
                        }
                    }
                }
            }
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
    }
    
    private func reminderRow(_ reminder: DepositReminder) -> some View {
        HStack(spacing: ExitSpacing.md) {
            // 정보
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text(reminder.name)
                    .font(.Exit.body)
                    .foregroundStyle(reminder.isEnabled ? Color.Exit.primaryText : Color.Exit.tertiaryText)
                
                Text(reminder.descriptionText)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            // 토글
            Toggle("", isOn: Binding(
                get: { reminder.isEnabled },
                set: { _ in viewModel.toggleReminder(reminder) }
            ))
            .labelsHidden()
            .tint(Color.Exit.accent)
        }
        .padding(ExitSpacing.md)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.openEditReminderSheet(reminder)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteReminder(reminder)
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Data Management Section
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Button {
                viewModel.showDeleteConfirm = true
            } label: {
                HStack {
                    Text("모든 데이터 삭제")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.warning.opacity(0.8))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                .padding(ExitSpacing.md)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Contact Section
    
    @State private var showCopiedToast = false
    private let contactEmail = "woweverstudio@gmail.com"
    private let instagramURL = "https://www.instagram.com/woweverstudio/"
    
    private var contactSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            sectionHeader(title: "문의하기")
            
            VStack(spacing: 0) {
                // 이메일 복사
                Button {
                    UIPasteboard.general.string = contactEmail
                    showCopiedToast = true
                    
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopiedToast = false
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                            Text("이메일")
                                .font(.Exit.body)
                                .foregroundStyle(Color.Exit.primaryText)
                            
                            Text(contactEmail)
                                .font(.Exit.caption)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                        
                        Spacer()
                        
                        Text(showCopiedToast ? "복사됨" : "복사")
                            .font(.Exit.caption)
                            .foregroundStyle(showCopiedToast ? Color.Exit.accent : Color.Exit.tertiaryText)
                    }
                    .padding(ExitSpacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .background(Color.Exit.divider)
                    .padding(.leading, ExitSpacing.md)
                
                // 인스타그램
                Button {
                    openInstagram()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                            Text("인스타그램")
                                .font(.Exit.body)
                                .foregroundStyle(Color.Exit.primaryText)
                            
                            Text("@woweverstudio")
                                .font(.Exit.caption)
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                    .padding(ExitSpacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
    }
    
    private func openInstagram() {
        let appURL = URL(string: "instagram://user?username=woweverstudio")!
        let webURL = URL(string: instagramURL)!
        
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            sectionHeader(title: "앱 정보")
            
            HStack {
                Text("버전")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Spacer()
                
                Text("1.0.1")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.Exit.caption)
            .fontWeight(.medium)
            .foregroundStyle(Color.Exit.secondaryText)
            .padding(.leading, ExitSpacing.xs)
    }
}


// MARK: - Reminder Edit Sheet

struct ReminderEditSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var isEditing: Bool {
        viewModel.editingReminder != nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Exit.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: ExitSpacing.lg) {
                        // 이름 입력
                        nameSection
                        
                        // 반복 유형
                        repeatTypeSection
                        
                        // 날짜/요일 선택
                        if viewModel.reminderRepeatType == .monthly {
                            dayOfMonthSection
                        } else if viewModel.reminderRepeatType == .weekly {
                            dayOfWeekSection
                        }
                        
                        // 시간 선택
                        timeSection
                        
                        // 삭제 버튼 (수정 시에만)
                        if isEditing, let reminder = viewModel.editingReminder {
                            deleteButton(reminder)
                        }
                    }
                    .padding(ExitSpacing.lg)
                }
            }
            .navigationTitle(isEditing ? "알람 수정" : "알람 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(Color.Exit.secondaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        viewModel.saveReminder()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.reminderName.isEmpty ? Color.Exit.tertiaryText : Color.Exit.accent)
                    .disabled(viewModel.reminderName.isEmpty)
                }
            }
        }
//        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("알람 이름")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            TextField("예: 월급, 배당금", text: $viewModel.reminderName)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.primaryText)
                .padding(ExitSpacing.md)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
    }
    
    private var repeatTypeSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("반복")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            HStack(spacing: ExitSpacing.sm) {
                ForEach(RepeatType.allCases, id: \.self) { type in
                    Button {
                        viewModel.reminderRepeatType = type
                    } label: {
                        Text(type.rawValue)
                            .font(.Exit.caption)
                            .fontWeight(viewModel.reminderRepeatType == type ? .semibold : .regular)
                            .foregroundStyle(
                                viewModel.reminderRepeatType == type
                                ? Color.Exit.accent
                                : Color.Exit.secondaryText
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ExitSpacing.md)
                            .background(
                                viewModel.reminderRepeatType == type
                                ? Color.Exit.accent.opacity(0.1)
                                : Color.Exit.cardBackground
                            )
                            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var dayOfMonthSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("날짜")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            // 날짜 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: ExitSpacing.sm) {
                ForEach(1...31, id: \.self) { day in
                    Button {
                        viewModel.reminderDayOfMonth = day
                    } label: {
                        Text("\(day)")
                            .font(.Exit.caption)
                            .fontWeight(viewModel.reminderDayOfMonth == day ? .bold : .regular)
                            .foregroundStyle(
                                viewModel.reminderDayOfMonth == day
                                ? .white
                                : Color.Exit.primaryText
                            )
                            .frame(width: 36, height: 36)
                            .background(
                                viewModel.reminderDayOfMonth == day
                                ? Color.Exit.accent
                                : Color.Exit.cardBackground
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.secondaryCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
    }
    
    private var dayOfWeekSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("요일")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            HStack(spacing: ExitSpacing.sm) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    Button {
                        viewModel.reminderDayOfWeek = day
                    } label: {
                        Text(day.name)
                            .font(.Exit.caption)
                            .fontWeight(viewModel.reminderDayOfWeek == day ? .bold : .regular)
                            .foregroundStyle(
                                viewModel.reminderDayOfWeek == day
                                ? .white
                                : Color.Exit.primaryText
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ExitSpacing.md)
                            .background(
                                viewModel.reminderDayOfWeek == day
                                ? Color.Exit.accent
                                : Color.Exit.cardBackground
                            )
                            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("시간")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            DatePicker(
                "",
                selection: $viewModel.reminderTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
    }
    
    private func deleteButton(_ reminder: DepositReminder) -> some View {
        Button {
            viewModel.deleteReminder(reminder)
            dismiss()
        } label: {
            Text("알람 삭제")
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.warning.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExitSpacing.md)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView(
        viewModel: SettingsViewModel(),
        shouldNavigateToWelcome: .constant(false)
    )
    .preferredColorScheme(.dark)
    .environment(\.appState, AppStateManager())
}

