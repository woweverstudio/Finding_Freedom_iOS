//
//  StockCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  종목 카드 컴포넌트
//

import SwiftUI

/// 검색 결과 종목 카드
struct StockSearchCard: View {
    let stock: StockInfo
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: ExitSpacing.md) {
                // 섹터 이모지
                Text(stock.sectorEmoji)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(Color.Exit.secondaryCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                
                // 종목 정보
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: ExitSpacing.xs) {
                        Text(stock.displayName)
                            .font(.Exit.body)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.Exit.primaryText)
                            .lineLimit(1)
                        
                        Text(stock.exchange.flagEmoji)
                            .font(.caption)
                    }
                    
                    Text(stock.ticker)
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Spacer()
                
                // 추가 버튼
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.Exit.accent)
            }
            .padding(ExitSpacing.md)
            .background(Color.Exit.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        }
        .buttonStyle(.plain)
    }
}

/// 포트폴리오 내 종목 카드
struct PortfolioStockCard: View {
    let holding: PortfolioHoldingDisplay
    let onWeightChange: (Double) -> Void
    let onRemove: () -> Void
    
    @State private var isEditing = false
    @State private var tempWeight: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: ExitSpacing.md) {
                // 섹터 이모지
                Text(holding.sectorEmoji)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(Color.Exit.secondaryCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                
                // 종목 정보
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: ExitSpacing.xs) {
                        Text(holding.name)
                            .font(.Exit.body)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.Exit.primaryText)
                            .lineLimit(1)
                        
                        Text(holding.exchange.flagEmoji)
                            .font(.caption)
                    }
                    
                    Text(holding.ticker)
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                Spacer()
                
                // 비중 표시 / 편집
                if isEditing {
                    HStack(spacing: ExitSpacing.xs) {
                        TextField("", text: $tempWeight)
                            .font(.Exit.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.accent)
                            .keyboardType(.decimalPad)
                            .frame(width: 50)
                            .multilineTextAlignment(.trailing)
                            .onSubmit {
                                applyWeight()
                            }
                        
                        Text("%")
                            .font(.Exit.body)
                            .foregroundStyle(Color.Exit.accent)
                    }
                } else {
                    Button {
                        tempWeight = String(format: "%.1f", holding.weight * 100)
                        isEditing = true
                    } label: {
                        Text(holding.weightPercent)
                            .font(.Exit.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.accent)
                    }
                    .buttonStyle(.plain)
                }
                
                // 삭제 버튼
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(ExitSpacing.md)
            
            // 비중 슬라이더
            VStack(spacing: ExitSpacing.xs) {
                // 프로그레스 바
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 배경
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.Exit.divider)
                            .frame(height: 4)
                        
                        // 채워진 부분
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.Exit.accent)
                            .frame(width: geometry.size.width * holding.weight, height: 4)
                    }
                }
                .frame(height: 4)
                
                // 슬라이더 (드래그)
                Slider(value: Binding(
                    get: { holding.weight },
                    set: { onWeightChange($0) }
                ), in: 0...1, step: 0.01)
                .tint(Color.Exit.accent)
            }
            .padding(.horizontal, ExitSpacing.md)
            .padding(.bottom, ExitSpacing.md)
        }
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                applyWeight()
            }
        }
    }
    
    private func applyWeight() {
        isEditing = false
        if let value = Double(tempWeight), value >= 0, value <= 100 {
            onWeightChange(value / 100)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        StockSearchCard(
            stock: StockInfo(
                ticker: "AAPL",
                name: "Apple Inc.",
                nameKorean: "애플",
                exchange: .NASDAQ,
                sector: "Technology",
                currency: .USD
            ),
            onAdd: {}
        )
        
        PortfolioStockCard(
            holding: PortfolioHoldingDisplay(
                ticker: "AAPL",
                name: "애플",
                exchange: .NASDAQ,
                sectorEmoji: "💻",
                weight: 0.4
            ),
            onWeightChange: { _ in },
            onRemove: {}
        )
    }
    .padding()
    .background(Color.Exit.background)
}

