//
//  NumberFormatter+Exit.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation

/// Exit 앱 전용 숫자 포맷터
/// nonisolated로 선언하여 어떤 actor에서든 호출 가능
enum ExitNumberFormatter {
    
    // MARK: - 금액 포맷팅 (만원 단위)
    
    /// 원 단위를 "X,XXX만원" 형식으로 변환
    /// - Parameter value: 원 단위 금액
    /// - Returns: 포맷된 문자열 (예: "7,500만원")
    nonisolated static func formatToManWon(_ value: Double) -> String {
        let manWon = value / 10_000
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: manWon)) {
            return "\(formatted)만원"
        }
        return "0만원"
    }
    
    /// 원 단위를 "X,XXX만원" 형식으로 변환
    /// - Parameter value: 원 단위 금액
    /// - Returns: 포맷된 문자열 (예: "7,500만원")
    nonisolated static func formatToMan(_ value: Double) -> String {
        let manWon = value / 10_000
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: manWon)) {
            return "\(formatted)만"
        }
        return "0만"
    }
    
    /// 원 단위를 "X억 X,XXX만원" 형식으로 변환 (억 단위 포함)
    /// - Parameter value: 원 단위 금액
    /// - Returns: 포맷된 문자열 (예: "4억 2,750만원")
    nonisolated static func formatToEokManWon(_ value: Double) -> String {
        let eok = Int(value / 100_000_000)
        let remainingManWon = (value.truncatingRemainder(dividingBy: 100_000_000)) / 10_000
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if eok > 0 {
            if remainingManWon > 0 {
                if let manFormatted = formatter.string(from: NSNumber(value: remainingManWon)) {
                    return "\(eok)억 \(manFormatted)만원"
                }
            }
            return "\(eok)억원"
        } else {
            return formatToManWon(value)
        }
    }
    
    /// 원 단위를 "X억 X,XXX만" 형식으로 변환 (억 단위 포함)
    /// - Parameter value: 원 단위 금액
    /// - Returns: 포맷된 문자열 (예: "4억 2,750만")
    nonisolated static func formatToEokMan(_ value: Double) -> String {
        let eok = Int(value / 100_000_000)
        let remainingManWon = (value.truncatingRemainder(dividingBy: 100_000_000)) / 10_000
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if eok > 0 {
            if remainingManWon > 0 {
                if let manFormatted = formatter.string(from: NSNumber(value: remainingManWon)) {
                    return "\(eok)억 \(manFormatted)만"
                }
            }
            return "\(eok)억"
        } else {
            return formatToMan(value)
        }
    }
    
    /// 원 단위를 짧은 형식으로 변환 (차트용)
    /// - Parameter value: 원 단위 금액
    /// - Returns: 포맷된 문자열 (예: "150만")
    nonisolated static func formatToManWonShort(_ value: Double) -> String {
        let manWon = value / 10_000
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: manWon)) {
            return "\(formatted)만"
        }
        return "0"
    }
    
    /// 원 단위를 차트 Y축용 간결한 형식으로 변환
    /// - Parameter value: 원 단위 금액
    /// - Returns: 포맷된 문자열 (예: "3.5억", "0.7억", "500만")
    nonisolated static func formatChartAxis(_ value: Double) -> String {
        if value <= 0 { return "0" }
        
        let eok = value / 100_000_000
        
        if eok >= 1 {
            // 1억 이상: "3억", "3.5억" 형식
            if eok == floor(eok) {
                return String(format: "%.0f억", eok)
            } else {
                return String(format: "%.1f억", eok)
            }
        } else if eok >= 0.1 {
            // 0.1억(1000만원) 이상: "0.5억" 형식
            return String(format: "%.1f억", eok)
        } else {
            // 1000만원 미만: "500만" 형식
            let man = value / 10_000
            return String(format: "%.0f만", man)
        }
    }
    
    /// 축약된 금액 표시 (홈화면용)
    /// - Parameter value: 원 단위 금액
    /// - Returns: 포맷된 문자열 (예: "7,500만원 / 4억 2,750만원")
    nonisolated static func formatProgressDisplay(current: Double, target: Double) -> String {
        "\(formatToEokManWon(current)) / \(formatToEokManWon(target))"
    }
    
    // MARK: - 퍼센트 포맷팅
    
    /// 퍼센트 포맷 (소수점 1자리)
    /// - Parameter value: 0~100 사이의 퍼센트 값
    /// - Returns: 포맷된 문자열 (예: "28.5%")
    nonisolated static func formatPercent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }
    
    /// 퍼센트 포맷 (정수)
    /// - Parameter value: 0~100 사이의 퍼센트 값
    /// - Returns: 포맷된 문자열 (예: "28%")
    nonisolated static func formatPercentInt(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }
    
    // MARK: - 기간 포맷팅
    
    /// 개월 수를 "X년 Y개월" 형식으로 변환
    /// - Parameter months: 총 개월 수
    /// - Returns: 포맷된 문자열 (예: "7년 6개월")
    nonisolated static func formatMonthsToYearsMonths(_ months: Int) -> String {
        let years = months / 12
        let remainingMonths = months % 12
        
        if years > 0 && remainingMonths > 0 {
            return "\(years)년 \(remainingMonths)개월"
        } else if years > 0 {
            return "\(years)년"
        } else {
            return "\(remainingMonths)개월"
        }
    }
    
    // MARK: - 점수 포맷팅
    
    /// 점수 포맷 (정수)
    /// - Parameter value: 점수 값
    /// - Returns: 포맷된 문자열 (예: "84점")
    nonisolated static func formatScore(_ value: Double) -> String {
        "\(Int(value))점"
    }
    
    /// 점수 변화 포맷
    /// - Parameter change: 변화량
    /// - Returns: 포맷된 문자열 (예: "↑5점" 또는 "↓3점")
    nonisolated static func formatScoreChange(_ change: Double) -> String {
        if change >= 0 {
            return "↑\(Int(change))점"
        } else {
            return "↓\(Int(abs(change)))점"
        }
    }
    
    // MARK: - 입력용 포맷팅
    
    /// 숫자 문자열을 원 단위로 파싱
    /// - Parameter string: 입력된 문자열
    /// - Returns: 원 단위 금액
    nonisolated static func parseToWon(_ string: String) -> Double {
        let cleanString = string.replacingOccurrences(of: ",", with: "")
                                .replacingOccurrences(of: "만원", with: "")
                                .replacingOccurrences(of: "원", with: "")
                                .replacingOccurrences(of: " ", with: "")
        return Double(cleanString) ?? 0
    }
    
    /// 입력 중인 금액을 포맷팅 (천 단위 쉼표)
    /// - Parameter value: 원 단위 금액
    /// - Returns: 포맷된 문자열 (예: "75,000,000")
    nonisolated static func formatInputDisplay(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    /// 원 단위 포맷 (천 단위 쉼표 + "원")
    /// - Parameter value: 원 단위 금액
    /// - Returns: 포맷된 문자열 (예: "75,000,000원")
    nonisolated static func formatToWon(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: abs(value))) {
            let sign = value < 0 ? "-" : ""
            return "\(sign)\(formatted)원"
        }
        return "0원"
    }
    
    /// 원 단위 포맷 (천 단위 쉼표만, "원" 없음)
    /// - Parameter value: 원 단위 금액
    /// - Returns: 포맷된 문자열 (예: "75,000,000")
    nonisolated static func formatWithComma(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        
        if let formatted = formatter.string(from: NSNumber(value: abs(value))) {
            let sign = value < 0 ? "-" : ""
            return "\(sign)\(formatted)"
        }
        return "0"
    }
}

