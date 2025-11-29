//
//  ScenarioSettingsView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI
import SwiftData

/// 시나리오 설정 풀스크린 시트
struct ScenarioSettingsView: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedScenario: Scenario?
    @State private var isEditing = false
    @State private var showNewScenarioAlert = false
    @State private var newScenarioName = ""
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 헤더
                header
                
                // 시나리오 탭
                scenarioTabs
                
                // 편집 영역
                if let scenario = selectedScenario {
                    ScrollView {
                        VStack(spacing: ExitSpacing.lg) {
                            // 현재 선택 표시
                            HStack {
                                Text("현재 선택:")
                                    .font(.Exit.subheadline)
                                    .foregroundStyle(Color.Exit.secondaryText)
                                
                                Text(scenario.name)
                                    .font(.Exit.body)
                                    .foregroundStyle(Color.Exit.accent)
                                
                                if scenario.isActive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.Exit.accent)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, ExitSpacing.lg)
                            
                            // 편집 필드들
                            scenarioFields(for: scenario)
                            
                            // 액션 버튼들
                            actionButtons(for: scenario)
                        }
                        .padding(.vertical, ExitSpacing.lg)
                    }
                }
                
                // 저장 버튼
                saveButton
            }
        }
        .onAppear {
            selectedScenario = viewModel.activeScenario ?? viewModel.scenarios.first
        }
        .alert("새 시나리오", isPresented: $showNewScenarioAlert) {
            TextField("시나리오 이름", text: $newScenarioName)
            Button("취소", role: .cancel) {
                newScenarioName = ""
            }
            Button("생성") {
                if !newScenarioName.isEmpty {
                    viewModel.createNewScenario(name: newScenarioName)
                    viewModel.loadData()
                    newScenarioName = ""
                }
            }
        }
        .alert("이름 변경", isPresented: $showRenameAlert) {
            TextField("새 이름", text: $renameText)
            Button("취소", role: .cancel) {
                renameText = ""
            }
            Button("변경") {
                if let scenario = selectedScenario, !renameText.isEmpty {
                    viewModel.renameScenario(scenario, to: renameText)
                    renameText = ""
                }
            }
        }
        .alert("시나리오 삭제", isPresented: $showDeleteConfirm) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                if let scenario = selectedScenario {
                    viewModel.deleteScenario(scenario)
                    selectedScenario = viewModel.scenarios.first
                }
            }
        } message: {
            Text("이 시나리오를 삭제하시겠습니까?")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            Text("시나리오 선택 및 편집")
                .font(.Exit.title3)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            // 균형용
            Image(systemName: "xmark")
                .font(.Exit.body)
                .foregroundStyle(.clear)
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.vertical, ExitSpacing.lg)
    }
    
    // MARK: - Scenario Tabs
    
    private var scenarioTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ExitSpacing.sm) {
                ForEach(viewModel.scenarios, id: \.id) { scenario in
                    ScenarioTab(
                        name: scenario.name,
                        isSelected: scenario.id == selectedScenario?.id,
                        isActive: scenario.isActive
                    ) {
                        withAnimation {
                            selectedScenario = scenario
                        }
                    }
                }
                
                // 새 시나리오 버튼
                if viewModel.scenarios.count < ScenarioManager.maxScenarios {
                    Button {
                        showNewScenarioAlert = true
                    } label: {
                        HStack(spacing: ExitSpacing.xs) {
                            Image(systemName: "plus")
                            Text("새 시나리오")
                        }
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.accent)
                        .padding(.horizontal, ExitSpacing.md)
                        .padding(.vertical, ExitSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: ExitRadius.full)
                                .stroke(Color.Exit.accent, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, ExitSpacing.lg)
        }
        .padding(.bottom, ExitSpacing.md)
    }
    
    // MARK: - Scenario Fields
    
    private func scenarioFields(for scenario: Scenario) -> some View {
        VStack(spacing: ExitSpacing.md) {
            ScenarioField(
                title: "은퇴 후 희망 월 수입",
                value: Binding(
                    get: { scenario.desiredMonthlyIncome },
                    set: { scenario.desiredMonthlyIncome = $0 }
                ),
                formatter: ExitNumberFormatter.formatToManWon
            )
            
            // 현재 순자산 (읽기 전용 - 실제 Asset에서 가져옴)
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text("현재 순자산 (실제)")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack {
                    Text(ExitNumberFormatter.formatToEokManWon(viewModel.currentAssetAmount))
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Spacer()
                    
                    Text("자산 업데이트에서 수정")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                .padding(ExitSpacing.md)
                .background(Color.Exit.secondaryCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
            .padding(.horizontal, ExitSpacing.lg)
            
            // 가정 금액 (시나리오별)
            ScenarioField(
                title: "가정 금액",
                subtitle: "\"만약 자산이 더/덜 있다면?\" 시뮬레이션용",
                value: Binding(
                    get: { scenario.assetOffset },
                    set: { scenario.assetOffset = $0 }
                ),
                formatter: { value in
                    let prefix = value >= 0 ? "+" : ""
                    return prefix + ExitNumberFormatter.formatToEokManWon(value)
                },
                allowNegative: true
            )
            
            // 시나리오에 적용될 총 자산 (계산값)
            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                Text("시나리오 적용 자산")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                
                HStack {
                    let effectiveAsset = scenario.effectiveAsset(with: viewModel.currentAssetAmount)
                    Text(ExitNumberFormatter.formatToEokManWon(effectiveAsset))
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.accent)
                    
                    Spacer()
                    
                    Text("= 실제 자산 + 가정 금액")
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                .padding(ExitSpacing.md)
                .background(Color.Exit.accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            }
            .padding(.horizontal, ExitSpacing.lg)
            
            ScenarioField(
                title: "매월 목표 투자금액",
                value: Binding(
                    get: { scenario.monthlyInvestment },
                    set: { scenario.monthlyInvestment = $0 }
                ),
                formatter: ExitNumberFormatter.formatToManWon
            )
            
            ScenarioPercentField(
                title: "은퇴 전 연 목표 수익률",
                value: Binding(
                    get: { scenario.preRetirementReturnRate },
                    set: { scenario.preRetirementReturnRate = $0 }
                )
            )
            
            ScenarioPercentField(
                title: "은퇴 후 연 목표 수익률",
                value: Binding(
                    get: { scenario.postRetirementReturnRate },
                    set: { scenario.postRetirementReturnRate = $0 }
                )
            )
            
            ScenarioPercentField(
                title: "예상 물가 상승률",
                value: Binding(
                    get: { scenario.inflationRate },
                    set: { scenario.inflationRate = $0 }
                )
            )
        }
    }
    
    // MARK: - Action Buttons
    
    private func actionButtons(for scenario: Scenario) -> some View {
        HStack(spacing: ExitSpacing.md) {
            Button {
                viewModel.duplicateScenario(scenario)
                viewModel.loadData()
            } label: {
                Label("복제하기", systemImage: "doc.on.doc")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .padding(ExitSpacing.sm)
                    .background(Color.Exit.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
            }
            .disabled(viewModel.scenarios.count >= ScenarioManager.maxScenarios)
            
            Button {
                renameText = scenario.name
                showRenameAlert = true
            } label: {
                Label("이름 바꾸기", systemImage: "pencil")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .padding(ExitSpacing.sm)
                    .background(Color.Exit.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
            }
            
            Button {
                showDeleteConfirm = true
            } label: {
                Label("삭제하기", systemImage: "trash")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.warning)
                    .padding(ExitSpacing.sm)
                    .background(Color.Exit.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
            }
            .disabled(viewModel.scenarios.count <= 1)
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            if let scenario = selectedScenario {
                viewModel.selectScenario(scenario)
                viewModel.updateScenario(scenario)
            }
            dismiss()
        } label: {
            Text("저장하고 적용하기")
                .exitPrimaryButton()
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.bottom, ExitSpacing.xl)
    }
}

// MARK: - Scenario Tab

private struct ScenarioTab: View {
    let name: String
    let isSelected: Bool
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: ExitSpacing.xs) {
                Text(name)
                    .font(.Exit.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.Exit.secondaryText)
            .padding(.horizontal, ExitSpacing.md)
            .padding(.vertical, ExitSpacing.sm)
            .background(
                Group {
                    if isSelected {
                        LinearGradient.exitAccent
                    } else {
                        Color.Exit.cardBackground
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.full))
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.full)
                    .stroke(isSelected ? Color.clear : Color.Exit.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scenario Field

private struct ScenarioField: View {
    let title: String
    var subtitle: String? = nil
    @Binding var value: Double
    let formatter: (Double) -> String
    var allowNegative: Bool = false
    
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
            Text(title)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            
            HStack {
                Text(formatter(value))
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Spacer()
                
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.accent)
                }
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
        .padding(.horizontal, ExitSpacing.lg)
        .sheet(isPresented: $isEditing) {
            AmountEditSheet(title: title, value: $value, formatter: formatter, allowNegative: allowNegative)
        }
    }
}

// MARK: - Scenario Percent Field

private struct ScenarioPercentField: View {
    let title: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
            Text(title)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            HStack {
                Text(String(format: "%.1f%%", value))
                    .font(.Exit.body)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Spacer()
                
                HStack(spacing: ExitSpacing.sm) {
                    Button {
                        if value > 0 {
                            value -= 0.5
                        }
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    
                    Button {
                        if value < 20 {
                            value += 0.5
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.accent)
                    }
                }
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
        .padding(.horizontal, ExitSpacing.lg)
    }
}

// MARK: - Amount Edit Sheet

private struct AmountEditSheet: View {
    let title: String
    @Binding var value: Double
    let formatter: (Double) -> String
    var allowNegative: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @State private var editValue: Double = 0
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            VStack(spacing: ExitSpacing.lg) {
                // 헤더
                HStack {
                    Button { dismiss() } label: {
                        Text("취소")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text(title)
                        .font(.Exit.title3)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Spacer()
                    
                    Button {
                        value = editValue
                        dismiss()
                    } label: {
                        Text("완료")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.accent)
                    }
                }
                .padding(.horizontal, ExitSpacing.lg)
                .padding(.top, ExitSpacing.lg)
                
                Spacer()
                
                // 금액 표시
                VStack(spacing: ExitSpacing.sm) {
                    Text(ExitNumberFormatter.formatInputDisplay(editValue))
                        .font(.Exit.numberDisplay)
                        .foregroundStyle(editValue < 0 ? Color.Exit.warning : Color.Exit.primaryText)
                    
                    Text(formatter(editValue))
                        .font(.Exit.title3)
                        .foregroundStyle(Color.Exit.accent)
                }
                
                Spacer()
                
                // 키보드
                CustomNumberKeyboard(value: $editValue, showNegativeToggle: allowNegative)
            }
        }
        .onAppear {
            editValue = value
        }
        .presentationDetents([.large])
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Scenario.self, Asset.self, configurations: config)
    
    // 샘플 시나리오 생성
    let scenarios = Scenario.createDefaultScenarios(
        desiredMonthlyIncome: 3_000_000,
        currentNetAssets: 75_000_000,
        monthlyInvestment: 2_000_000
    )
    
    for scenario in scenarios {
        container.mainContext.insert(scenario)
    }
    
    let viewModel = HomeViewModel()
    viewModel.scenarios = scenarios
    viewModel.activeScenario = scenarios.first
    
    return ScenarioSettingsView(viewModel: viewModel)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
