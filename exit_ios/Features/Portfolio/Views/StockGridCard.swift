//
//  StockGridCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  종목 그리드 카드 (인기 종목용 - 3열 그리드)
//

import SwiftUI

/// 종목 그리드 카드 (인기 종목용 - 3열 그리드)
struct StockGridCard: View {
    let stock: StockInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: ExitSpacing.sm) {
                // 로고 이미지
                StockLogoImage(
                    ticker: stock.ticker,
                    iconUrl: stock.iconUrl,
                    size: 48
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.Exit.accent : Color.clear, lineWidth: 2)
                )
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.Exit.accent)
                            .background(Circle().fill(Color.Exit.background))
                            .offset(x: 4, y: -4)
                    }
                }
                
                // 메인 표시명 (ETF는 티커, 주식은 회사명)
                Text(stock.displayName)
                    .font(.Exit.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                // 서브 표시명 (ETF는 풀네임, 주식은 티커)
                Text(stock.subDisplayName)
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                    .lineLimit(1)
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
