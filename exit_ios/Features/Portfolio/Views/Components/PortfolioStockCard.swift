//
//  StockCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  종목 카드 컴포넌트
//

import SwiftUI

/// 포트폴리오 내 종목 카드 (2열 그리드용 컴팩트 디자인)
struct PortfolioStockCard: View {
    let holding: PortfolioHoldingDisplay
    let onWeightChange: (Double) -> Void
    let onRemove: () -> Void
    
    /// 비중 퍼센트 (0-100)
    private var weightPercent: Int {
        Int(holding.weight * 100)
    }
    
    var body: some View {
        VStack(spacing: ExitSpacing.md) {
            HStack {
                // 로고 이미지
                StockLogoImage(
                    ticker: holding.ticker,
                    iconUrl: holding.iconUrl,
                    size: 30
                )
                
                VStack(alignment: .leading) {
                    Text(holding.stockType == .commonStock ? holding.ticker : holding.name)
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.primaryText)
                        .lineLimit(1)
                    
                    Text(holding.stockType == .commonStock ? holding.name : holding.subName)
                        .font(.Exit.caption2)
                        .foregroundStyle(Color.Exit.secondaryText)
                        .lineLimit(1)
                }
                
                
                Spacer()
            }
            
            weightComponent
        }
        .padding(ExitSpacing.sm)
        .padding(.top, ExitSpacing.xs)
        .background(Color.Exit.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.md))
        .overlay(alignment: .topTrailing) {
            // 삭제 버튼 (우상단 overlay)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .frame(width: 22, height: 22)
                    .background(Color.Exit.secondaryCardBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(ExitSpacing.xs)
        }
    }
    
    var weightComponent: some View {
        // 비중 슬라이더 영역
        VStack(spacing: ExitSpacing.sm) {
            // 퍼센트 표시 + +/- 버튼
            HStack(spacing: ExitSpacing.sm) {
                // - 버튼
                Button {
                    let newWeight = max(0, holding.weight - 0.01)
                    onWeightChange(newWeight)
                    HapticService.shared.light()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(weightPercent > 0 ? Color.Exit.secondaryText : Color.Exit.tertiaryText)
                        .frame(width: 36, height: 32)
                        .background(Color.Exit.secondaryCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                }
                .buttonStyle(.plain)
                .disabled(weightPercent <= 0)
                
                Spacer()
                
                // 퍼센트 표시
                Text("\(weightPercent)%")
                    .font(.Exit.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.Exit.accent)
                    .monospacedDigit()
                    .frame(minWidth: 40)
                
                Spacer()
                
                // + 버튼
                Button {
                    let newWeight = min(1, holding.weight + 0.01)
                    onWeightChange(newWeight)
                    HapticService.shared.light()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(weightPercent < 100 ? Color.Exit.secondaryText : Color.Exit.tertiaryText)
                        .frame(width: 36, height: 32)
                        .background(Color.Exit.secondaryCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: ExitRadius.sm))
                }
                .buttonStyle(.plain)
                .disabled(weightPercent >= 100)
            }
            
            // 슬라이더
            Slider(
                value: Binding(
                    get: { holding.weight },
                    set: { newValue in
                        // 1% 단위로 반올림
                        let rounded = (newValue * 100).rounded() / 100
                        onWeightChange(rounded)
                    }
                ),
                in: 0...1,
                step: 0.01
            )
            .tint(Color.Exit.accent)
        }
        .padding(.horizontal, ExitSpacing.xs)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PortfolioStockCard(
            holding: PortfolioHoldingDisplay(
                ticker: "SCHD",
                name: "SCHD",
                subName: "Schwab U.S. Dividend Equity ETF",
                exchange: .ARCA,
                sectorEmoji: "📊",
                iconUrl: nil,
                stockType: .etf,
                weight: 0.4
            ),
            onWeightChange: { _ in },
            onRemove: {}
        )
    }
    .padding()
    .background(Color.Exit.background)
}
