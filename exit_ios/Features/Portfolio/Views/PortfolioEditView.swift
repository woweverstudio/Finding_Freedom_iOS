//
//  PortfolioEditView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 편집 뷰 (종목 추가/제거, 비중 조절)
//

import SwiftUI

/// 포트폴리오 편집 뷰
struct PortfolioEditView: View {
    @Bindable var viewModel: PortfolioViewModel
    let onBack: () -> Void
    let isPurchased: Bool
    
    @State private var showSearchSheet = false
    
    init(
        viewModel: PortfolioViewModel,
        onBack: @escaping () -> Void,
        isPurchased: Bool
    ) {
        self.viewModel = viewModel
        self.onBack = onBack
        self.isPurchased = isPurchased
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerSection
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: ExitSpacing.lg) {
                    // 종목 목록
                    holdingsSection
                    
                    // 종목 추가 버튼
                    addStockButton
                    
                    // 비중 조절 도구
                    if !viewModel.holdings.isEmpty {
                        weightToolsSection
                    }
                }
                .padding(ExitSpacing.md)
                .padding(.bottom, !viewModel.holdings.isEmpty ? 80 : 0)
            }
            
            // 플로팅 분석 버튼
            if !viewModel.holdings.isEmpty {
                analyzeButton
            }
        }
        .fullScreenCover(isPresented: $showSearchSheet) {
            StockSearchSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            
            Spacer()
            
            Text("포트폴리오 편집")
                .font(.Exit.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.Exit.primaryText)
            
            Spacer()
            
            // 균형용
            Image(systemName: "chevron.left")
                .font(.system(size: 16))
                .foregroundStyle(.clear)
        }
        .padding(ExitSpacing.md)
    }
    
    // MARK: - Holdings Section
    
    private var holdingsSection: some View {
        VStack(spacing: ExitSpacing.md) {
            if viewModel.holdings.isEmpty {
                // 빈 상태 안내
                VStack(spacing: ExitSpacing.md) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    VStack(spacing: ExitSpacing.xs) {
                        Text("포트폴리오가 비어있어요")
                            .font(.Exit.body)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.Exit.secondaryText)
                        
                        Text("아래 버튼을 눌러 종목을 추가해주세요")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.tertiaryText)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExitSpacing.xl)
            } else {
                ForEach(viewModel.holdings) { holding in
                    PortfolioStockCard(
                        holding: holding,
                        onWeightChange: { newWeight in
                            viewModel.updateWeight(for: holding.ticker, weight: newWeight)
                        },
                        onRemove: {
                            withAnimation(.spring(response: 0.3)) {
                                if let index = viewModel.holdings.firstIndex(where: { $0.id == holding.id }) {
                                    viewModel.removeStock(at: index)
                                }
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .push(from: .trailing),
                        removal: .push(from: .leading)
                    ))
                }
            }
        }
    }
    
    // MARK: - Add Stock Button
    
    private var addStockButton: some View {
        Button {
            showSearchSheet = true
        } label: {
            HStack(spacing: ExitSpacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                
                Text("종목 추가")
                    .font(.Exit.body)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.Exit.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.Exit.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .stroke(Color.Exit.accent.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [8]))
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Weight Tools
    
    private var weightToolsSection: some View {
        HStack(spacing: ExitSpacing.md) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    viewModel.equalizeWeights()
                }
                HapticService.shared.light()
            } label: {
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "equal.circle.fill")
                        .font(.system(size: 16))
                    Text("균등 배분")
                        .font(.Exit.caption)
                }
                .foregroundStyle(Color.Exit.secondaryText)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.vertical, ExitSpacing.sm)
                .background(Color.Exit.secondaryCardBackground)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            if !viewModel.isWeightValid && viewModel.totalWeight > 0 {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.normalizeWeights()
                    }
                    HapticService.shared.light()
                } label: {
                    HStack(spacing: ExitSpacing.xs) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16))
                        Text("100%로 조정")
                            .font(.Exit.caption)
                    }
                    .foregroundStyle(Color.Exit.accent)
                    .padding(.horizontal, ExitSpacing.md)
                    .padding(.vertical, ExitSpacing.sm)
                    .background(Color.Exit.accent.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Analyze Button (Floating)
    
    private var analyzeButton: some View {
        Group {
            if !viewModel.isWeightValid {
                // 비중이 100%가 아닐 때
                VStack(spacing: 0) {
                    Text("비중을 100%로 맞춰주세요 (현재 \(String(format: "%.0f", viewModel.totalWeight * 100))%)")
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.Exit.secondaryCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
                }
                .padding(.horizontal, ExitSpacing.md)
                .padding(.bottom, ExitSpacing.md)
            } else {
                // 비중이 100%일 때
                ExitCTAButton(
                    title: isPurchased ? "포트폴리오 분석하기" : "프리미엄 구매 후 분석 가능",
                    icon: isPurchased ? "play.fill" : "sparkles",
                    isEnabled: isPurchased && viewModel.canAnalyze,
                    isLoading: viewModel.isLoading,
                    action: {
                        if isPurchased {
                            Task {
                                await viewModel.analyze()
                            }
                        }
                    }
                )
                .padding(.horizontal, ExitSpacing.md)
                .padding(.bottom, ExitSpacing.md)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = PortfolioViewModel()
    
    return ZStack {
        Color.Exit.background.ignoresSafeArea()
        PortfolioEditView(
            viewModel: viewModel,
            onBack: {},
            isPurchased: false
        )
    }
    .onAppear {
        Task {
            await viewModel.loadInitialData()
        }
    }
}
