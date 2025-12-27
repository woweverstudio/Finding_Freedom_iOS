//
//  MenuView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import SwiftData

/// 메뉴(설정) 화면 메인 뷰
struct MenuView: View {
    @Environment(\.appState) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.storeService) private var storeService
    @Bindable var viewModel: MenuViewModel
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
                    
                    // 인앱결제 섹션
                    purchaseSection
                    
                    // 입금 알람 섹션
                    reminderSection
                    
                    // 문의하기 섹션
                    contactSection
                    
                    // 테마 설정 섹션
                    themeSection
                    
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
                appState.resetToHomeTab()
                viewModel.deleteAllData()
                shouldNavigateToWelcome = true
            }
        } message: {
            Text("모든 입금 기록, 자산 정보, 시나리오가 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.")
        }
    }
    
    // MARK: - Section Header
    
    private func sectionHeader(title: String, trailing: AnyView? = nil) -> some View {
        HStack {
            Text(title)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Spacer()
            
            if let trailing = trailing {
                trailing
            }
        }
        .padding(.leading, ExitSpacing.xs)
    }
    
    // MARK: - Announcement Section
    
    private var announcementSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            sectionHeader(title: "공지사항")
            
            Button {
                viewModel.showAnnouncementList = true
            } label: {
                ExitCard(style: .filled, padding: ExitSpacing.md, radius: ExitRadius.md) {
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
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            sectionHeader(
                title: "구매 항목",
                trailing: AnyView(
                    Button {
                        Task {
                            await storeService.restorePurchases()
                        }
                    } label: {
                        Text("구매 복원")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.accent)
                    }
                    .buttonStyle(.plain)
                )
            )
            
            ExitCard(style: .filled, padding: 0, radius: ExitRadius.md) {
                VStack(spacing: 0) {
                    // 몬테카를로 시뮬레이션
                    purchaseRow(
                        title: "몬테카를로 시뮬레이션",
                        description: "은퇴 시뮬레이션 기능",
                        isPurchased: storeService.hasMontecarloSimulation
                    )
                    
                    ExitDivider()
                        .padding(.leading, ExitSpacing.md)
                    
                    // 포트폴리오 분석
                    purchaseRow(
                        title: "포트폴리오 분석",
                        description: "상세 포트폴리오 분석 기능",
                        isPurchased: storeService.hasPortfolioAnalysis
                    )
                }
            }
        }
    }
    
    private func purchaseRow(title: String, description: String, isPurchased: Bool) -> some View {
        HStack(spacing: ExitSpacing.md) {
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text(title)
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(description)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            // 구매 상태 표시
            if isPurchased {
                ExitBadge(text: "구매완료", icon: "checkmark.circle.fill", color: Color.Exit.accent, style: .subtle)
            } else {
                ExitBadge(text: "미구매", color: Color.Exit.tertiaryText, style: .subtle)
            }
        }
        .padding(ExitSpacing.md)
    }
    
    // MARK: - Reminder Section
    
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            sectionHeader(
                title: "알람",
                trailing: AnyView(
                    Button {
                        viewModel.openAddReminderSheet()
                    } label: {
                        Text("추가")
                            .font(.Exit.caption)
                            .foregroundStyle(viewModel.isNotificationEnabled ? Color.Exit.accent : Color.Exit.tertiaryText)
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.isNotificationEnabled)
                )
            )
            
            ExitCard(style: .filled, padding: 0, radius: ExitRadius.md) {
                VStack(spacing: 0) {
                    // 알림 권한 토글 (항상 최상단)
                    notificationPermissionRow
                    
                    ExitDivider()
                        .padding(.leading, ExitSpacing.md)
                    
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
                                ExitDivider()
                                    .padding(.leading, ExitSpacing.md)
                            }
                        }
                    }
                }
            }
            
            // 알림 권한 안내 (권한이 꺼져있을 때만)
            if !viewModel.isNotificationEnabled {
                notificationPermissionGuide
            }
        }
        .onAppear {
            viewModel.checkNotificationPermissionStatus()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                viewModel.checkNotificationPermissionStatus()
            }
        }
    }
    
    /// 알림 권한 토글 Row
    private var notificationPermissionRow: some View {
        HStack(spacing: ExitSpacing.md) {
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text("알림 권한")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text("알림을 받으려면 권한이 필요해요")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { viewModel.isNotificationEnabled },
                set: { _ in viewModel.toggleNotificationPermission() }
            ))
            .labelsHidden()
            .tint(Color.Exit.accent)
        }
        .padding(ExitSpacing.md)
    }
    
    /// 알림 권한 안내 문구 (권한 꺼져있을 때)
    private var notificationPermissionGuide: some View {
        Button {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        } label: {
            Text("설정 → 알림에서 권한을 켜주세요")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.warning)
        }
        .buttonStyle(.plain)
        .padding(.leading, ExitSpacing.xs)
    }
    
    private func reminderRow(_ reminder: DepositReminder) -> some View {
        HStack(spacing: ExitSpacing.md) {
            // 정보
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text(reminder.name)
                    .font(.Exit.body)
                    .foregroundStyle(
                        viewModel.isNotificationEnabled && reminder.isEnabled
                        ? Color.Exit.primaryText
                        : Color.Exit.tertiaryText
                    )
                
                Text(reminder.descriptionText)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            // 토글 (알림 권한이 있을 때만 활성화)
            Toggle("", isOn: Binding(
                get: { reminder.isEnabled },
                set: { _ in viewModel.toggleReminder(reminder) }
            ))
            .labelsHidden()
            .tint(Color.Exit.accent)
            .disabled(!viewModel.isNotificationEnabled)
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
                ExitCard(style: .filled, padding: ExitSpacing.md, radius: ExitRadius.md) {
                    HStack {
                        Text("모든 데이터 삭제")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.warning.opacity(0.8))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
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
            
            ExitCard(style: .filled, padding: 0, radius: ExitRadius.md) {
                VStack(spacing: 0) {
                    // 이메일 복사
                    Button {
                        UIPasteboard.general.string = contactEmail
                        showCopiedToast = true
                        HapticService.shared.light()
                        
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
                    
                    ExitDivider()
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
            }
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
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            sectionHeader(title: "화면 설정")
            
            HStack(spacing: ExitSpacing.sm) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    themeButton(theme)
                }
            }
        }
    }
    
    private func themeButton(_ theme: AppTheme) -> some View {
        let isSelected = appState.appTheme == theme
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appState.setTheme(theme)
            }
            HapticService.shared.light()
        } label: {
            HStack(spacing: ExitSpacing.sm) {
                Image(systemName: theme.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Color.Exit.accent : Color.Exit.tertiaryText)
                
                Text(theme.rawValue)
                    .font(.Exit.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.Exit.accent : Color.Exit.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ExitSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .fill(isSelected ? Color.Exit.accent.opacity(0.1) : Color.Exit.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .stroke(isSelected ? Color.Exit.accent : Color.Exit.divider, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - App Info Section
    
    /// 앱 버전 (Bundle에서 로드)
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
    }
    
    /// 앱 빌드 번호 (Bundle에서 로드)
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    }
    
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            sectionHeader(title: "앱 정보")
            
            ExitCard(style: .filled, padding: ExitSpacing.md, radius: ExitRadius.md) {
                HStack {
                    Text("버전")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Spacer()
                    
                    Text("\(appVersion) (\(appBuild))")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
            }
        }
    }
}


// MARK: - Reminder Edit Sheet

struct ReminderEditSheet: View {
    @Bindable var viewModel: MenuViewModel
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
        .presentationDragIndicator(.visible)
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("알람 이름")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            ExitTextField(
                placeholder: "예: 월급, 배당금",
                text: $viewModel.reminderName
            )
        }
    }
    
    private var repeatTypeSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("반복")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            HStack(spacing: ExitSpacing.sm) {
                ForEach(RepeatType.allCases, id: \.self) { type in
                    ExitChip(
                        text: type.rawValue,
                        isSelected: viewModel.reminderRepeatType == type
                    ) {
                        viewModel.reminderRepeatType = type
                    }
                }
            }
        }
    }
    
    private var dayOfMonthSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("날짜")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            ExitCard(style: .filled, padding: ExitSpacing.md, radius: ExitRadius.md) {
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
                                    : Color.Exit.secondaryCardBackground
                                )
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var dayOfWeekSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("요일")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            HStack(spacing: ExitSpacing.sm) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    ExitChip(
                        text: day.name,
                        isSelected: viewModel.reminderDayOfWeek == day
                    ) {
                        viewModel.reminderDayOfWeek = day
                    }
                }
            }
        }
    }
    
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("시간")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            ExitCard(style: .filled, padding: 0, radius: ExitRadius.md) {
                DatePicker(
                    "",
                    selection: $viewModel.reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func deleteButton(_ reminder: DepositReminder) -> some View {
        ExitButton(
            title: "알람 삭제",
            style: .destructive,
            size: .medium
        ) {
            viewModel.deleteReminder(reminder)
            dismiss()
        }
    }
}

#Preview {
    MenuView(
        viewModel: MenuViewModel(),
        shouldNavigateToWelcome: .constant(false)
    )
    .preferredColorScheme(.dark)
    .environment(\.appState, AppStateManager())
    .environment(\.storeService, StoreKitService())
}
