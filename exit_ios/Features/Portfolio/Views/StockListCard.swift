//
//  StockListCard.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  종목 리스트 카드 (검색 결과용 - 1열 리스트)
//

import SwiftUI

/// 종목 리스트 카드 (검색 결과용 - 1열 리스트)
struct StockListCard: View {
    let stock: StockInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ExitSpacing.md) {
                // 로고 이미지
                StockLogoImage(
                    ticker: stock.ticker,
                    iconUrl: stock.iconUrl,
                    size: 44
                )
                
                // 종목 정보
                VStack(alignment: .leading, spacing: 2) {
                    Text(stock.displayName)
                        .font(.Exit.body)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.Exit.primaryText)
                        .lineLimit(1)
                    
                    Text(stock.subDisplayName)
                        .font(.Exit.caption)
                        .foregroundStyle(Color.Exit.tertiaryText)
                        .lineLimit(1)
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
