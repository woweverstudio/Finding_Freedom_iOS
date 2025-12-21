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

/// 포트폴리오 내 종목 카드 (컴팩트 디자인)
struct PortfolioStockCard: View {
    let holding: PortfolioHoldingDisplay
    let onWeightChange: (Double) -> Void
    let onRemove: () -> Void
    
    @State private var isEditing = false
    @State private var tempWeight: String = ""
    @FocusState private var isInputFocused: Bool
    
    /// 비중 퍼센트 (0-100)
    private var weightPercent: Double {
        holding.weight * 100
    }
    
    var body: some View {
        VStack(spacing: ExitSpacing.sm) {
            // 상단: 종목 정보 + 삭제 버튼
            HStack(spacing: ExitSpacing.md) {
                // CI 이미지 placeholder
                ZStack {
                    Circle()
                        .fill(Color.Exit.secondaryCardBackground)
                        .frame(width: 40, height: 40)
                    
                    Text(String(holding.ticker.prefix(1)))
                        .font(.Exit.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                // 종목 정보 (넓게, 2줄 허용)
                VStack(alignment: .leading, spacing: 2) {
                    Text(holding.name)
                        .font(.Exit.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.primaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(holding.ticker)
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.tertiaryText)
                }
                
                Spacer()
                
                // 삭제 버튼
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .frame(width: 24, height: 24)
                        .background(Color.Exit.secondaryCardBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            
            // 하단: 비중 조절 컨트롤 (슬라이더 + 버튼)
            HStack(spacing: ExitSpacing.sm) {
                // 마이너스 버튼
                Button {
                    adjustWeight(by: -0.01)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.Exit.secondaryText)
                        .frame(width: 28, height: 28)
                        .background(Color.Exit.secondaryCardBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // 슬라이더
                Slider(value: Binding(
                    get: { holding.weight },
                    set: { onWeightChange($0) }
                ), in: 0...1, step: 0.01)
                .tint(Color.Exit.accent)
                
                // 플러스 버튼
                Button {
                    adjustWeight(by: 0.01)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.Exit.secondaryText)
                        .frame(width: 28, height: 28)
                        .background(Color.Exit.secondaryCardBackground)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                // 비중 표시 / 직접 입력
                if isEditing {
                    HStack(spacing: 2) {
                        TextField("", text: $tempWeight)
                            .font(.Exit.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.accent)
                            .keyboardType(.decimalPad)
                            .frame(width: 36)
                            .multilineTextAlignment(.trailing)
                            .focused($isInputFocused)
                            .onSubmit {
                                applyWeight()
                            }
                        
                        Text("%")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.accent)
                    }
                    .padding(.horizontal, ExitSpacing.xs)
                    .padding(.vertical, 4)
                    .background(Color.Exit.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Button {
                        tempWeight = String(format: "%.0f", weightPercent)
                        isEditing = true
                        isInputFocused = true
                    } label: {
                        Text(String(format: "%.0f%%", weightPercent))
                            .font(.Exit.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Exit.accent)
                            .frame(width: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(ExitSpacing.md)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        .onChange(of: isInputFocused) { _, focused in
            if !focused && isEditing {
                applyWeight()
            }
        }
    }
    
    private func adjustWeight(by delta: Double) {
        let newWeight = max(0, min(1, holding.weight + delta))
        onWeightChange(newWeight)
        HapticService.shared.light()
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

