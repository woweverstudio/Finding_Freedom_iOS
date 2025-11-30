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
    @Bindable var viewModel: SettingsViewModel
    @Binding var shouldNavigateToWelcome: Bool
    
    var body: some View {
        ZStack {
            // 배경
            Color.Exit.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: ExitSpacing.lg) {
                        // 공지사항 섹션
                        announcementSection
                        
                        // 입금 알람 섹션
                        reminderSection
                        
                        // 데이터 관리 섹션
                        dataManagementSection
                        
                        // 문의하기 섹션
                        contactSection
                        
                        // 앱 정보 섹션
                        appInfoSection
                    }
                    .padding(.horizontal, ExitSpacing.md)
                    .padding(.vertical, ExitSpacing.lg)
                }
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
                viewModel.deleteAllData()
                shouldNavigateToWelcome = true
            }
        } message: {
            Text("모든 입금 기록, 자산 정보, 시나리오가 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.")
        }
    }
    
    // MARK: - Announcement Section
    
    private var announcementSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            sectionHeader(title: "공지사항", icon: "megaphone.fill")
            
            if let latestAnnouncement = viewModel.announcements.first {
                Button {
                    // 공지사항 리스트로 이동
                    viewModel.showAnnouncementList = true
                } label: {
                    HStack(spacing: ExitSpacing.md) {
                        // 타입 아이콘
                        ZStack {
                            Circle()
                                .fill(Color(hex: latestAnnouncement.type.color).opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: latestAnnouncement.type.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: latestAnnouncement.type.color))
                        }
                        
                        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                            // 타입 뱃지 + 날짜
                            HStack(spacing: ExitSpacing.xs) {
                                Text(latestAnnouncement.type.rawValue)
                                    .font(.Exit.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color(hex: latestAnnouncement.type.color))
                                
                                Text("•")
                                    .font(.Exit.caption2)
                                    .foregroundStyle(Color.Exit.tertiaryText)
                                
                                Text(latestAnnouncement.relativeTimeText)
                                    .font(.Exit.caption2)
                                    .foregroundStyle(Color.Exit.tertiaryText)
                            }
                            
                            // 제목
                            Text(latestAnnouncement.title)
                                .font(.Exit.body)
                                .fontWeight(latestAnnouncement.isRead ? .regular : .semibold)
                                .foregroundStyle(latestAnnouncement.isRead ? Color.Exit.secondaryText : Color.Exit.primaryText)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // 읽지 않음 표시
                        if !latestAnnouncement.isRead {
                            Circle()
                                .fill(Color.Exit.accent)
                                .frame(width: 8, height: 8)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                    .padding(ExitSpacing.md)
                    .background(Color.Exit.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                }
                .buttonStyle(.plain)
            } else {
                // 공지사항이 없을 때
                HStack {
                    Text("공지사항이 없습니다")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Spacer()
                }
                .padding(ExitSpacing.md)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
        }
    }
    
    // MARK: - Reminder Section
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            HStack {
                sectionHeader(title: "입금 알람", icon: "bell.fill")
                
                Spacer()
                
                Button {
                    viewModel.openAddReminderSheet()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.Exit.accent)
                }
                .buttonStyle(.plain)
            }
            
            if viewModel.depositReminders.isEmpty {
                // 빈 상태
                VStack(spacing: ExitSpacing.md) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    Text("등록된 알람이 없습니다")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text("월급일이나 배당금 입금일에\n알람을 설정해보세요")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        viewModel.openAddReminderSheet()
                    } label: {
                        Text("알람 추가하기")
                            .font(.Exit.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, ExitSpacing.lg)
                            .padding(.vertical, ExitSpacing.sm)
                            .background(LinearGradient.exitAccent)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExitSpacing.xl)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            } else {
                // 알람 리스트
                VStack(spacing: 0) {
                    ForEach(viewModel.depositReminders, id: \.id) { reminder in
                        reminderRow(reminder)
                        
                        if reminder.id != viewModel.depositReminders.last?.id {
                            Divider()
                                .background(Color.Exit.divider)
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
        }
    }
    
    private func reminderRow(_ reminder: DepositReminder) -> some View {
        HStack(spacing: ExitSpacing.md) {
            // 아이콘
            Image(systemName: reminder.repeatType.icon)
                .font(.system(size: 20))
                .foregroundStyle(reminder.isEnabled ? Color.Exit.accent : Color.Exit.tertiaryText)
                .frame(width: 32)
            
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
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            sectionHeader(title: "데이터 관리", icon: "externaldrive.fill")
            
            Button {
                viewModel.showDeleteConfirm = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.Exit.warning)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                        Text("모든 데이터 삭제")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.warning)
                        
                        Text("입금 기록, 자산 정보, 시나리오 모두 삭제")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
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
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            sectionHeader(title: "문의하기", icon: "envelope.fill")
            
            VStack(spacing: 0) {
                // 이메일 복사
                Button {
                    UIPasteboard.general.string = contactEmail
                    showCopiedToast = true
                    
                    // 햅틱 피드백
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    // 토스트 자동 숨김
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showCopiedToast = false
                    }
                } label: {
                    HStack(spacing: ExitSpacing.md) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.Exit.accent)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                            Text("이메일")
                                .font(.Exit.body)
                                .foregroundStyle(Color.Exit.primaryText)
                            
                            Text(contactEmail)
                                .font(.Exit.caption)
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                        
                        Spacer()
                        
                        if showCopiedToast {
                            Text("복사됨")
                                .font(.Exit.caption)
                                .foregroundStyle(Color.Exit.accent)
                        } else {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                    }
                    .padding(ExitSpacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .background(Color.Exit.divider)
                    .padding(.leading, 48)
                
                // 인스타그램
                Button {
                    openInstagram()
                } label: {
                    HStack(spacing: ExitSpacing.md) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "E4405F")) // 인스타그램 색상
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                            Text("인스타그램")
                                .font(.Exit.body)
                                .foregroundStyle(Color.Exit.primaryText)
                            
                            Text("@woweverstudio")
                                .font(.Exit.caption)
                                .foregroundStyle(Color.Exit.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
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
        // 인스타그램 앱 URL
        let appURL = URL(string: "instagram://user?username=woweverstudio")!
        // 웹 URL (fallback)
        let webURL = URL(string: instagramURL)!
        
        // 인스타그램 앱이 설치되어 있으면 앱으로, 아니면 웹으로
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.md) {
            sectionHeader(title: "앱 정보", icon: "info.circle.fill")
            
            VStack(spacing: 0) {
                infoRow(title: "버전", value: "1.0.0")
            }
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.secondaryText)
        }
        .padding(ExitSpacing.md)
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: ExitSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.Exit.accent)
            
            Text(title)
                .font(.Exit.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.Exit.secondaryText)
        }
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
                        VStack(spacing: ExitSpacing.xs) {
                            Image(systemName: type.icon)
                                .font(.system(size: 20))
                            Text(type.rawValue)
                                .font(.Exit.caption2)
                        }
                        .foregroundStyle(
                            viewModel.reminderRepeatType == type
                            ? Color.Exit.accent
                            : Color.Exit.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ExitSpacing.md)
                        .background(
                            viewModel.reminderRepeatType == type
                            ? Color.Exit.accent.opacity(0.15)
                            : Color.Exit.cardBackground
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: ExitRadius.md)
                                .stroke(
                                    viewModel.reminderRepeatType == type
                                    ? Color.Exit.accent
                                    : Color.Exit.divider,
                                    lineWidth: 1
                                )
                        )
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
            HStack {
                Image(systemName: "trash.fill")
                Text("알람 삭제")
            }
            .font(.Exit.body)
            .foregroundStyle(Color.Exit.warning)
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
}

