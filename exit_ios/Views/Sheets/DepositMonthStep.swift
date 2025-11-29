//
//  DepositMonthStep.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 스텝1: 월 선택 뷰
struct DepositMonthStep: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    let currentYear: Int
    let currentMonth: Int
    let existingMonths: Set<String>
    let hasExistingRecord: Bool
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: ExitSpacing.xl) {
            // 안내 텍스트
            Text("어느 달을 기록할까요?")
                .font(.Exit.title2)
                .foregroundStyle(Color.Exit.primaryText)
                .padding(.top, ExitSpacing.xl)
            
            // 년/월 캘린더
            MonthCalendarPicker(
                selectedYear: $selectedYear,
                selectedMonth: $selectedMonth,
                currentYear: currentYear,
                currentMonth: currentMonth,
                existingMonths: existingMonths
            )
            .padding(.horizontal, ExitSpacing.md)
            
            Spacer()
            
            if hasExistingRecord {
                HStack(spacing: ExitSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("기존 기록이 있어요")
                        .font(.Exit.caption)
                }
                .foregroundStyle(Color.Exit.accent)
            }
            
            // 다음 버튼
            Button(action: onNext) {
                Text("다음")
                    .exitPrimaryButton(isEnabled: true)
            }
            .padding(.horizontal, ExitSpacing.md)
            .padding(.bottom, ExitSpacing.lg)
        }
    }
}

// MARK: - Month Calendar Picker

struct MonthCalendarPicker: View {
    @Binding var selectedYear: Int
    @Binding var selectedMonth: Int
    let currentYear: Int
    let currentMonth: Int
    let existingMonths: Set<String>
    
    var body: some View {
        VStack(spacing: ExitSpacing.lg) {
            // 년도 선택
            yearSelector
            
            // 월 그리드
            monthGrid
        }
    }
    
    private var yearSelector: some View {
        HStack(spacing: ExitSpacing.xl) {
            // 이전 년도
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    selectedYear -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.Exit.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(Color.Exit.secondaryCardBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 년도 표시
            Text("\(String(selectedYear))년")
                .font(.Exit.title2)
                .foregroundStyle(Color.Exit.primaryText)
                .contentTransition(.numericText())
            
            Spacer()
            
            // 다음 년도
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    if selectedYear < currentYear {
                        selectedYear += 1
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(selectedYear >= currentYear ? Color.Exit.tertiaryText : Color.Exit.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(Color.Exit.secondaryCardBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(selectedYear >= currentYear)
        }
    }
    
    private var monthGrid: some View {
        VStack(spacing: ExitSpacing.sm) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: ExitSpacing.sm) {
                    ForEach(0..<4, id: \.self) { col in
                        let monthIndex = row * 4 + col + 1
                        MonthCell(
                            month: monthIndex,
                            isSelected: selectedMonth == monthIndex,
                            isFuture: isFutureMonth(monthIndex),
                            hasRecord: hasRecord(month: monthIndex),
                            onTap: {
                                if !isFutureMonth(monthIndex) {
                                    selectedMonth = monthIndex
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    private func isFutureMonth(_ month: Int) -> Bool {
        if selectedYear > currentYear { return true }
        if selectedYear == currentYear && month > currentMonth { return true }
        return false
    }
    
    private func hasRecord(month: Int) -> Bool {
        let yearMonth = String(format: "%04d%02d", selectedYear, month)
        return existingMonths.contains(yearMonth)
    }
}

// MARK: - Month Cell

struct MonthCell: View {
    let month: Int
    let isSelected: Bool
    let isFuture: Bool
    let hasRecord: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Text("\(month)월")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                
                // 기록 표시 점
                Circle()
                    .fill(hasRecord ? Color.Exit.accent : Color.clear)
                    .frame(width: 6, height: 6)
                    .offset(x: 0, y: 24)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ExitRadius.md)
                    .stroke(isSelected ? Color.Exit.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }
    
    private var textColor: Color {
        if isFuture {
            return Color.Exit.tertiaryText
        }
        if isSelected {
            return Color.Exit.accent
        }
        return Color.Exit.primaryText
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.Exit.accent.opacity(0.15)
        }
        return Color.Exit.secondaryCardBackground
    }
}

