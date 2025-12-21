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
                    
                    // 분석 버튼
                    if !viewModel.holdings.isEmpty {
                        analyzeButton
                    }
                }
                .padding(ExitSpacing.lg)
            }
        }
        .fullScreenCover(isPresented: $showSearchSheet) {
            StockSearchSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: ExitSpacing.sm) {
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
            .padding(.bottom, ExitSpacing.md)
            
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
    
    // MARK: - Analyze Button
    
    private var analyzeButton: some View {
        Button {
            if isPurchased {
                // 구매한 경우: 분석 실행
                Task {
                    await viewModel.analyze()
                }
            } else {
                // 미구매: 구매 유도 (현재는 아무 동작 없음, 필요시 구매 화면으로 이동)
            }
        } label: {
            HStack(spacing: ExitSpacing.sm) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    if isPurchased {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 18))
                        
                        Text("포트폴리오 분석하기")
                            .font(.Exit.body)
                            .fontWeight(.semibold)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                        
                        Text("프리미엄 구매 후 분석 가능")
                            .font(.Exit.body)
                            .fontWeight(.semibold)
                    }
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                (isPurchased && viewModel.canAnalyze)
                    ? LinearGradient.exitAccent
                    : LinearGradient(colors: [Color.Exit.disabledBackground], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
        .buttonStyle(.plain)
        .disabled((!isPurchased || !viewModel.canAnalyze) || viewModel.isLoading)
        .padding(.top, ExitSpacing.md)
    }
}

/// 종목 검색 시트 (풀스크린, 다중선택)
struct StockSearchSheet: View {
    @Bindable var viewModel: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    
    /// 선택된 종목 티커 목록
    @State private var selectedTickers: Set<String> = []
    
    /// 인기 종목 티커 (미리 정의)
    private let popularTickers = [
        "AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "META",
        "TSLA", "VOO", "QQQ", "VTI", "SCHD", "SPY"
    ]
    
    /// 인기 종목 필터링
    private var popularStocks: [StockInfo] {
        popularTickers.compactMap { ticker in
            viewModel.allStocks.first { $0.ticker == ticker }
        }
    }
    
    /// 이미 포트폴리오에 추가된 티커
    private var addedTickers: Set<String> {
        Set(viewModel.holdings.map { $0.ticker })
    }
    
    /// 검색 중인지 여부
    private var isSearching: Bool {
        !viewModel.searchQuery.isEmpty
    }
    
    /// 3열 그리드 레이아웃
    private let gridColumns = [
        GridItem(.flexible(), spacing: ExitSpacing.sm),
        GridItem(.flexible(), spacing: ExitSpacing.sm),
        GridItem(.flexible(), spacing: ExitSpacing.sm)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 검색바
                searchBar
                
                // 선택된 종목 수 표시
                if !selectedTickers.isEmpty {
                    selectedCountBadge
                }
                
                // 콘텐츠
                if viewModel.isLoading {
                    loadingView
                } else if isSearching {
                    // 검색 중: 1열 리스트
                    searchResultsList
                } else {
                    // 초기 화면: 인기 종목 3열 그리드
                    popularStocksGrid
                }
                
                Spacer(minLength: 0)
                
                // 하단 완료 버튼
                if !selectedTickers.isEmpty {
                    confirmButton
                }
            }
            .background(Color.Exit.background)
            .navigationTitle("종목 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundStyle(Color.Exit.secondaryText)
                }
            }
        }
        .interactiveDismissDisabled(!selectedTickers.isEmpty)
        .onAppear {
            // 기존에 추가된 종목들을 선택 상태로 초기화
            selectedTickers = addedTickers
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: ExitSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(Color.Exit.tertiaryText)
            
            TextField("종목명 또는 티커 검색", text: $viewModel.searchQuery)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.primaryText)
                .focused($isSearchFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: viewModel.searchQuery) { _, _ in
                    Task {
                        await viewModel.search()
                    }
                }
            
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    isSearchFocused = false
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
    }
    
    // MARK: - Selected Count Badge
    
    private var selectedCountBadge: some View {
        HStack {
            Text("\(selectedTickers.count)개 종목 선택됨")
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.accent)
            
            Spacer()
            
            Button {
                // 새로 선택한 것만 해제 (기존 포트폴리오 종목은 유지)
                selectedTickers = addedTickers
            } label: {
                Text("선택 초기화")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.secondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.vertical, ExitSpacing.sm)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(Color.Exit.accent)
            Spacer()
        }
    }
    
    // MARK: - Popular Stocks Grid
    
    private var popularStocksGrid: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: ExitSpacing.md) {
                // 섹션 헤더
                Text("인기 종목")
                    .font(.Exit.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                    .padding(.horizontal, ExitSpacing.lg)
                    .padding(.top, ExitSpacing.md)
                
                // 3열 그리드
                LazyVGrid(columns: gridColumns, spacing: ExitSpacing.sm) {
                    ForEach(popularStocks) { stock in
                        StockGridCard(
                            stock: stock,
                            isSelected: selectedTickers.contains(stock.ticker)
                        ) {
                            toggleSelection(stock)
                        }
                    }
                }
                .padding(.horizontal, ExitSpacing.lg)
                
                // 전체 종목 섹션
                Text("전체 종목")
                    .font(.Exit.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                    .padding(.horizontal, ExitSpacing.lg)
                    .padding(.top, ExitSpacing.lg)
                
                // 전체 종목 그리드
                LazyVGrid(columns: gridColumns, spacing: ExitSpacing.sm) {
                    ForEach(viewModel.allStocks.filter { !popularTickers.contains($0.ticker) }) { stock in
                        StockGridCard(
                            stock: stock,
                            isSelected: selectedTickers.contains(stock.ticker)
                        ) {
                            toggleSelection(stock)
                        }
                    }
                }
                .padding(.horizontal, ExitSpacing.lg)
                .padding(.bottom, ExitSpacing.xl)
            }
        }
    }
    
    // MARK: - Search Results List
    
    private var searchResultsList: some View {
        Group {
            if viewModel.searchResults.isEmpty {
                VStack(spacing: ExitSpacing.sm) {
                    Spacer()
                    Text("😢")
                        .font(.system(size: 40))
                    Text("검색 결과가 없어요")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.secondaryText)
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: ExitSpacing.sm) {
                        ForEach(viewModel.searchResults) { stock in
                            StockListCard(
                                stock: stock,
                                isSelected: selectedTickers.contains(stock.ticker)
                            ) {
                                toggleSelection(stock)
                            }
                        }
                    }
                    .padding(ExitSpacing.lg)
                }
            }
        }
    }
    
    // MARK: - Confirm Button
    
    private var confirmButton: some View {
        Button {
            applySelection()
            dismiss()
        } label: {
            HStack(spacing: ExitSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                
                Text("선택 완료")
                    .font(.Exit.body)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(LinearGradient.exitAccent)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, ExitSpacing.lg)
        .padding(.bottom, ExitSpacing.lg)
    }
    
    // MARK: - Actions
    
    private func toggleSelection(_ stock: StockInfo) {
        HapticService.shared.light()
        
        if selectedTickers.contains(stock.ticker) {
            selectedTickers.remove(stock.ticker)
        } else {
            selectedTickers.insert(stock.ticker)
        }
    }
    
    private func applySelection() {
        // 새로 추가할 종목들
        let newTickers = selectedTickers.subtracting(addedTickers)
        // 제거할 종목들
        let removedTickers = addedTickers.subtracting(selectedTickers)
        
        // 새 종목 추가
        for ticker in newTickers {
            if let stock = viewModel.allStocks.first(where: { $0.ticker == ticker }) {
                viewModel.addStock(stock)
            }
        }
        
        // 종목 제거
        for ticker in removedTickers {
            if let index = viewModel.holdings.firstIndex(where: { $0.ticker == ticker }) {
                viewModel.removeStock(at: index)
            }
        }
        
        HapticService.shared.success()
    }
}

// MARK: - Stock Grid Card (인기 종목용 - 3열 그리드)

struct StockGridCard: View {
    let stock: StockInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: ExitSpacing.sm) {
                // CI 이미지 placeholder
                ZStack {
                    Circle()
                        .fill(Color.Exit.secondaryCardBackground)
                        .frame(width: 48, height: 48)
                    
                    // 종목 이니셜 (CI 이미지가 없을 때)
                    Text(String(stock.ticker.prefix(1)))
                        .font(.Exit.body)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.Exit.accent : Color.clear, lineWidth: 2)
                )
                .overlay(alignment: .bottomTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.Exit.accent)
                            .background(Circle().fill(Color.Exit.background))
                            .offset(x: 4, y: 4)
                    }
                }
                
                // 회사명
                Text(stock.displayName)
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // 티커
                Text(stock.ticker)
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ExitSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .fill(isSelected ? Color.Exit.accent.opacity(0.1) : Color.Exit.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .stroke(isSelected ? Color.Exit.accent.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stock List Card (검색 결과용 - 1열 리스트)

struct StockListCard: View {
    let stock: StockInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ExitSpacing.md) {
                // CI 이미지 placeholder
                ZStack {
                    Circle()
                        .fill(Color.Exit.secondaryCardBackground)
                        .frame(width: 44, height: 44)
                    
                    Text(String(stock.ticker.prefix(1)))
                        .font(.Exit.body)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                // 종목 정보
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.displayName)
                        .font(.Exit.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.primaryText)
                        .lineLimit(1)
                    
                    Text(stock.ticker)
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                
                Spacer()
                
                // 선택 상태 표시
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? Color.Exit.accent : Color.Exit.tertiaryText)
            }
            .padding(ExitSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .fill(isSelected ? Color.Exit.accent.opacity(0.1) : Color.Exit.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .stroke(isSelected ? Color.Exit.accent.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

