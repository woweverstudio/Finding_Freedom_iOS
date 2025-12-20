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
    @State private var showSearchSheet = false
    
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
                    
                    // 분석 버튼
                    if !viewModel.holdings.isEmpty {
                        analyzeButton
                    }
                }
                .padding(ExitSpacing.lg)
            }
        }
        .sheet(isPresented: $showSearchSheet) {
            StockSearchSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: ExitSpacing.sm) {
            HStack {
                Text("내 포트폴리오")
                    .font(.Exit.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Spacer()
                
                if !viewModel.holdings.isEmpty {
                    Button {
                        viewModel.resetPortfolio()
                    } label: {
                        Text("초기화")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.warning)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 비중 합계 표시
            if !viewModel.holdings.isEmpty {
                HStack {
                    Text("총 비중:")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                    
                    Text(String(format: "%.1f%%", viewModel.totalWeight * 100))
                        .font(.Exit.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.isWeightValid ? Color.Exit.accent : Color.Exit.warning)
                    
                    if !viewModel.isWeightValid {
                        Text("(100%가 되어야 해요)")
                            .font(.Exit.caption2)
                            .foregroundStyle(Color.Exit.warning)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.Exit.accent)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.vertical, ExitSpacing.md)
    }
    
    // MARK: - Holdings Section
    
    private var holdingsSection: some View {
        VStack(spacing: ExitSpacing.md) {
            ForEach(viewModel.holdings.indices, id: \.self) { index in
                let holding = viewModel.holdings[index]
                
                PortfolioStockCard(
                    holding: holding,
                    onWeightChange: { newWeight in
                        viewModel.updateWeight(for: holding.ticker, weight: newWeight)
                    },
                    onRemove: {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.removeStock(at: index)
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
    
    // MARK: - Analyze Button
    
    private var analyzeButton: some View {
        Button {
            Task {
                await viewModel.analyze()
            }
        } label: {
            HStack(spacing: ExitSpacing.sm) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 18))
                    
                    Text("포트폴리오 분석하기")
                        .font(.Exit.body)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                viewModel.canAnalyze
                    ? LinearGradient.exitAccent
                    : LinearGradient(colors: [Color.Exit.disabledBackground], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAnalyze || viewModel.isLoading)
        .padding(.top, ExitSpacing.md)
    }
}

/// 종목 검색 시트
struct StockSearchSheet: View {
    @Bindable var viewModel: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 검색바
                HStack(spacing: ExitSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.Exit.tertiaryText)
                    
                    TextField("종목명 또는 티커 검색", text: $viewModel.searchQuery)
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.primaryText)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.searchQuery) { _, _ in
                            Task {
                                await viewModel.search()
                            }
                        }
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.Exit.tertiaryText)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(ExitSpacing.md)
                .background(Color.Exit.secondaryCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
                .padding(.horizontal, ExitSpacing.lg)
                .padding(.top, ExitSpacing.md)
                
                // 검색 결과
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color.Exit.accent)
                    Spacer()
                } else if viewModel.filteredSearchResults.isEmpty {
                    Spacer()
                    VStack(spacing: ExitSpacing.sm) {
                        Text("😢")
                            .font(.system(size: 40))
                        Text("검색 결과가 없어요")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.secondaryText)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: ExitSpacing.sm) {
                            ForEach(viewModel.filteredSearchResults) { stock in
                                StockSearchCard(stock: stock) {
                                    viewModel.addStock(stock)
                                    HapticService.shared.light()
                                    dismiss()
                                }
                            }
                        }
                        .padding(ExitSpacing.lg)
                    }
                }
            }
            .background(Color.Exit.background)
            .navigationTitle("종목 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(Color.Exit.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            isSearchFocused = true
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = PortfolioViewModel()
    
    return ZStack {
        Color.Exit.background.ignoresSafeArea()
        PortfolioEditView(viewModel: viewModel)
    }
    .onAppear {
        Task {
            await viewModel.loadInitialData()
        }
    }
}

