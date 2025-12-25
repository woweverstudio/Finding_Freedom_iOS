//
//  StockSearchSheet.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  종목 검색 시트 (풀스크린, 다중선택)
//

import SwiftUI
import Combine

/// 종목 검색 시트 (풀스크린, 다중선택)
struct StockSearchSheet: View {
    @Bindable var viewModel: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    
    /// 선택된 종목 티커 목록
    @State private var selectedTickers: Set<String> = []
    
    /// 디바운싱용 검색어
    @State private var debouncedSearchQuery = ""
    
    /// 검색 디바운서
    @State private var searchTask: Task<Void, Never>?
    
    /// 검색 중 상태
    @State private var isSearchingAPI = false
    
    /// 에러 메시지
    @State private var errorMessage: String?
    
    /// 인기 종목 티커 (미리 정의)
    private let popularTickers = [
        // ETF
        "SCHD", "QQQM", "SPYM", "JEPQ", "JEPI",
        // 빅테크
        "AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "META", "TSLA"
    ]
    
    /// 인기 종목 필터링
    private var popularStocks: [StockInfo] {
        popularTickers.compactMap { ticker in
            viewModel.allStocks.first { $0.ticker == ticker }
        }
    }
    
    /// 선택 히스토리에서 가져온 종목들 (allStocks, searchResults, 캐시에서 찾기)
    private var historyStocks: [StockInfo] {
        StockSelectionHistory.shared.getHistory().compactMap { ticker in
            // 1. allStocks에서 찾기
            if let stock = viewModel.allStocks.first(where: { $0.ticker == ticker }) {
                return stock
            }
            // 2. searchResults에서 찾기
            if let stock = viewModel.searchResults.first(where: { $0.ticker == ticker }) {
                return stock
            }
            // 3. 캐시에서 찾기
            return StockDataCache.shared.getAllCachedStocks().first(where: { $0.ticker == ticker })
        }
    }
    
    /// 히스토리가 있는지 여부 (실제로 표시할 종목이 있는지)
    private var hasHistory: Bool {
        !historyStocks.isEmpty
    }
    
    /// 이미 포트폴리오에 추가된 티커
    private var addedTickers: Set<String> {
        Set(viewModel.holdings.map { $0.ticker })
    }
    
    /// 검색 중인지 여부
    private var isSearching: Bool {
        !viewModel.searchQuery.isEmpty
    }
    
    /// 디바운스 딜레이 (초)
    private let debounceDelay: Double = 0.3
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 검색바
                searchBar
                
                // 에러 메시지
                if let error = errorMessage {
                    errorBanner(error)
                }
                
                // 선택된 종목 수 표시
                selectedCountBadge
                
                // 콘텐츠
                if viewModel.isLoading || isSearchingAPI {
                    loadingView
                } else if isSearching {
                    // 검색 중: 1열 리스트
                    searchResultsList
                } else {
                    // 초기 화면: 최근 선택 / 인기 종목
                    popularStocksGrid
                }
                
                Spacer(minLength: 0)
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
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        applySelection()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
                }
            }
        }        
        .interactiveDismissDisabled(!selectedTickers.isEmpty)
        .onAppear {
            // 기존에 추가된 종목들을 선택 상태로 초기화
            selectedTickers = addedTickers
        }
        .onDisappear {
            // 진행 중인 검색 취소
            searchTask?.cancel()
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
                .onChange(of: viewModel.searchQuery) { oldValue, newValue in
                    debounceSearch(newValue)
                }
            
            // 검색 중 인디케이터
            if isSearchingAPI {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(Color.Exit.accent)
            } else if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    isSearchFocused = false
                    errorMessage = nil
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
        .padding(.horizontal, ExitSpacing.md)
        .padding(.top, ExitSpacing.md)
    }
    
    // MARK: - Error Banner
    
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: ExitSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.Exit.warning)
            
            Text(message)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            
            Spacer()
            
            Button {
                errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.Exit.tertiaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(ExitSpacing.sm)
        .background(Color.Exit.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
        .padding(.horizontal, ExitSpacing.md)
        .padding(.top, ExitSpacing.sm)
    }
    
    // MARK: - Selected Count Badge
    
    private var selectedCountBadge: some View {
        HStack {
            Text("\(selectedTickers.count)개 종목 선택됨")
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(selectedTickers.isEmpty ? Color.Exit.tertiaryText : Color.Exit.accent)
            
            Spacer()
        }
        .padding(.horizontal, ExitSpacing.md)
        .padding(.vertical, ExitSpacing.sm)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: ExitSpacing.md) {
            Spacer()
            ProgressView()
                .tint(Color.Exit.accent)
            Text("검색 중...")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            Spacer()
        }
    }
    
    // MARK: - Main Content List (히스토리 or 인기종목)
    
    private var popularStocksGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: ExitSpacing.sm) {
                if hasHistory {
                    // 최근 선택한 종목 섹션
                    recentSelectionSection
                    
                    // 인기 종목 섹션 (히스토리에 없는 것만)
                    let remainingPopular = popularStocks.filter { !StockSelectionHistory.shared.getHistory().contains($0.ticker) }
                    if !remainingPopular.isEmpty {
                        popularSection(stocks: remainingPopular)
                    }
                } else {
                    // 히스토리 없으면 인기 종목만
                    popularSection(stocks: popularStocks)
                }
            }
            .padding(.bottom, ExitSpacing.xl)
        }
        .scrollDismissesKeyboard(.immediately)
    }
    
    // MARK: - Recent Selection Section
    
    private var recentSelectionSection: some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("최근 선택")
                .font(.Exit.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.Exit.primaryText)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.top, ExitSpacing.md)
            
            ForEach(historyStocks) { stock in
                StockListCard(
                    stock: stock,
                    isSelected: selectedTickers.contains(stock.ticker)
                ) {
                    toggleSelection(stock)
                }
            }
            .padding(.horizontal, ExitSpacing.md)
        }
    }
    
    // MARK: - Popular Section
    
    private func popularSection(stocks: [StockInfo]) -> some View {
        VStack(alignment: .leading, spacing: ExitSpacing.sm) {
            Text("인기 종목")
                .font(.Exit.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.Exit.primaryText)
                .padding(.horizontal, ExitSpacing.md)
                .padding(.top, hasHistory ? ExitSpacing.lg : ExitSpacing.md)
            
            ForEach(stocks) { stock in
                StockListCard(
                    stock: stock,
                    isSelected: selectedTickers.contains(stock.ticker)
                ) {
                    toggleSelection(stock)
                }
            }
            .padding(.horizontal, ExitSpacing.md)
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
                    Text("다른 티커나 종목명으로 검색해보세요")
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.tertiaryText)
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
                    .padding(ExitSpacing.md)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
    }
    
    // MARK: - Debounced Search
    
    /// 디바운싱 적용 검색
    private func debounceSearch(_ query: String) {
        // 기존 검색 취소
        searchTask?.cancel()
        errorMessage = nil
        
        // 빈 검색어면 즉시 초기화
        guard !query.isEmpty else {
            isSearchingAPI = false
            return
        }
        
        // 새 검색 태스크 생성 (디바운싱)
        searchTask = Task {
            // 딜레이
            try? await Task.sleep(nanoseconds: UInt64(debounceDelay * 1_000_000_000))
            
            // 취소 확인
            if Task.isCancelled { return }
            
            // 검색 시작
            await MainActor.run {
                isSearchingAPI = true
            }
            
            await viewModel.search()
            
            await MainActor.run {
                isSearchingAPI = false
            }
        }
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
        
        // 실제로 추가된 종목들 (히스토리 저장용)
        var actuallyAddedTickers: [String] = []
        
        // 새 종목 추가 - 검색 결과와 전체 종목에서 찾기
        for ticker in newTickers {
            let stock = viewModel.allStocks.first(where: { $0.ticker == ticker }) ??
                        viewModel.searchResults.first(where: { $0.ticker == ticker }) ??
                        StockDataCache.shared.getAllCachedStocks().first(where: { $0.ticker == ticker })
            if let stock = stock {
                viewModel.addStock(stock)
                actuallyAddedTickers.append(ticker)
            }
        }
        
        // 실제로 추가된 종목만 히스토리에 저장
        if !actuallyAddedTickers.isEmpty {
            StockSelectionHistory.shared.addToHistory(actuallyAddedTickers)
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

// MARK: - Preview

#Preview {
    StockSearchSheet(viewModel: PortfolioViewModel())
}
