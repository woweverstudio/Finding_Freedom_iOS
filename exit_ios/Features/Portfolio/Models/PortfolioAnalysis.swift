//
//  PortfolioAnalysis.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 분석 결과 모델
//

import Foundation
import SwiftUI

// MARK: - Portfolio Analysis Result

/// 포트폴리오 분석 결과
struct PortfolioAnalysisResult {
    // MARK: - 수익 지표
    
    /// 가격 수익률만 (CAGR)
    let cagr: Double
    
    /// 배당 포함 CAGR
    let cagrWithDividends: Double
    
    /// 총 수익률 (배당 포함)
    let totalReturn: Double
    
    /// 가격 수익률
    let priceReturn: Double
    
    /// 배당 수익률
    let dividendReturn: Double
    
    // MARK: - 위험 지표
    
    /// 연간 변동성
    let volatility: Double
    
    /// 샤프 비율
    let sharpeRatio: Double
    
    /// 최대 낙폭 (MDD)
    let mdd: Double
    
    // MARK: - 배당 지표
    
    /// 현재 배당률
    let dividendYield: Double
    
    /// 배당 성장률 (5년)
    let dividendGrowthRate: Double
    
    // MARK: - 점수
    
    /// 종합 점수
    let score: PortfolioScore
    
    // MARK: - Computed Properties
    
    /// 분석 기간 (년)
    var analysisPeriodYears: Int {
        5  // Mock 데이터 기준
    }
}

// MARK: - Portfolio Score

/// 포트폴리오 점수
struct PortfolioScore {
    /// 총점 (0-100)
    let total: Int
    
    /// 수익성 점수 (40점 만점)
    let profitability: Int
    
    /// 안정성 점수 (30점 만점)
    let stability: Int
    
    /// 효율성 점수 (30점 만점)
    let efficiency: Int
    
    /// 등급 (S, A, B, C, D)
    var grade: String {
        switch total {
        case 90...100: return "S"
        case 80..<90: return "A"
        case 70..<80: return "B"
        case 60..<70: return "C"
        default: return "D"
        }
    }
    
    /// 등급 색상
    var gradeColor: Color {
        switch grade {
        case "S": return Color.Exit.accent
        case "A": return Color.Exit.positive
        case "B": return Color.Exit.caution
        case "C": return Color.Exit.warning
        default: return Color.Exit.warning
        }
    }
    
    /// 등급 설명
    var gradeDescription: String {
        switch grade {
        case "S": return "최상위 포트폴리오"
        case "A": return "우수한 포트폴리오"
        case "B": return "양호한 포트폴리오"
        case "C": return "개선이 필요해요"
        default: return "재검토가 필요해요"
        }
    }
}

// MARK: - Metric Types

/// 포트폴리오 지표 종류
enum PortfolioMetric: Identifiable {
    case cagr(Double)
    case sharpeRatio(Double)
    case mdd(Double)
    case volatility(Double)
    case dividendYield(Double)
    
    var id: String {
        switch self {
        case .cagr: return "cagr"
        case .sharpeRatio: return "sharpe"
        case .mdd: return "mdd"
        case .volatility: return "volatility"
        case .dividendYield: return "dividend"
        }
    }
    
    var title: String {
        switch self {
        case .cagr: return "연평균 수익률"
        case .sharpeRatio: return "위험조정수익률"
        case .mdd: return "최대 낙폭"
        case .volatility: return "변동성"
        case .dividendYield: return "배당률"
        }
    }
    
    var subtitle: String {
        switch self {
        case .cagr: return "CAGR"
        case .sharpeRatio: return "Sharpe Ratio"
        case .mdd: return "MDD"
        case .volatility: return "Volatility"
        case .dividendYield: return "Dividend Yield"
        }
    }
    
    var emoji: String {
        switch self {
        case .cagr: return "📈"
        case .sharpeRatio: return "⚖️"
        case .mdd: return "📉"
        case .volatility: return "🎢"
        case .dividendYield: return "💰"
        }
    }
    
    var value: Double {
        switch self {
        case .cagr(let v), .sharpeRatio(let v), .mdd(let v),
             .volatility(let v), .dividendYield(let v):
            return v
        }
    }
    
    var formattedValue: String {
        switch self {
        case .cagr(let v), .mdd(let v), .volatility(let v), .dividendYield(let v):
            return String(format: "%.1f%%", v * 100)
        case .sharpeRatio(let v):
            return String(format: "%.2f", v)
        }
    }
    
    var color: Color {
        switch self {
        case .cagr(let v):
            return v >= 0.10 ? .Exit.accent : (v >= 0.05 ? .Exit.positive : (v >= 0 ? .Exit.caution : .Exit.warning))
        case .sharpeRatio(let v):
            return v >= 1.5 ? .Exit.accent : (v >= 1.0 ? .Exit.positive : (v >= 0.5 ? .Exit.caution : .Exit.warning))
        case .mdd(let v):
            return abs(v) <= 0.15 ? .Exit.accent : (abs(v) <= 0.25 ? .Exit.positive : (abs(v) <= 0.35 ? .Exit.caution : .Exit.warning))
        case .volatility(let v):
            return v <= 0.15 ? .Exit.accent : (v <= 0.25 ? .Exit.positive : (v <= 0.35 ? .Exit.caution : .Exit.warning))
        case .dividendYield(let v):
            return v >= 0.03 ? .Exit.accent : (v >= 0.01 ? .Exit.positive : .Exit.secondaryText)
        }
    }
}

// MARK: - Metric Explanation

/// 지표 설명 데이터
struct MetricExplanation {
    let title: String
    let emoji: String
    let simpleExplanation: String
    let interpretationGuide: [(range: String, description: String, color: Color)]
    let tips: [String]?
    
    /// CAGR 설명 생성
    static func cagr(value: Double, years: Int) -> MetricExplanation {
        MetricExplanation(
            title: "연평균 수익률 (CAGR)",
            emoji: "📈",
            simpleExplanation: "매년 평균 몇 %씩 성장했는지 보여줘요. (최종가치/초기가치)^(1/년수) - 1 로 계산해요.",
            interpretationGuide: [
                ("10% 이상", "매우 좋은 성과 (S&P500 장기 평균)", .Exit.accent),
                ("5~10%", "양호한 성과", .Exit.positive),
                ("0~5%", "예금 수준", .Exit.caution),
                ("음수", "손실 발생", .Exit.warning)
            ],
            tips: nil
        )
    }
    
    /// Sharpe Ratio 설명 생성
    static func sharpeRatio(value: Double) -> MetricExplanation {
        MetricExplanation(
            title: "위험조정수익률 (Sharpe Ratio)",
            emoji: "⚖️",
            simpleExplanation: "감수한 위험 대비 얼마나 효율적으로 수익을 냈는지 보여줘요. (수익률 - 무위험수익률) ÷ 변동성 으로 계산해요.",
            interpretationGuide: [
                ("1.5 이상", "매우 우수 (헤지펀드 수준)", .Exit.accent),
                ("1.0~1.5", "우수 (좋은 전략)", .Exit.positive),
                ("0.5~1.0", "보통", .Exit.caution),
                ("0 미만", "무위험 자산보다 못함", .Exit.warning)
            ],
            tips: value < 1.0 ? [
                "상관관계가 낮은 자산으로 분산투자",
                "변동성이 낮은 종목 비중 늘리기",
                "채권 등 안전자산 일부 편입 고려"
            ] : nil
        )
    }
    
    /// MDD 설명 생성
    static func mdd(value: Double) -> MetricExplanation {
        MetricExplanation(
            title: "최대 낙폭 (MDD)",
            emoji: "📉",
            simpleExplanation: "역대 최고점에서 최저점까지 얼마나 떨어졌는지 보여줘요. (최저점 - 최고점) ÷ 최고점 으로 계산해요. 내가 감당할 수 있는 하락폭인지 확인해보세요!",
            interpretationGuide: [
                ("15% 이하", "안정적", .Exit.accent),
                ("15~25%", "보통", .Exit.positive),
                ("25~35%", "다소 높음", .Exit.caution),
                ("35% 이상", "높은 위험", .Exit.warning)
            ],
            tips: abs(value) > 0.25 ? [
                "변동성이 낮은 자산 추가",
                "분산투자 확대",
                "장기 투자 관점 유지"
            ] : nil
        )
    }
    
    /// 변동성 설명 생성
    static func volatility(value: Double) -> MetricExplanation {
        MetricExplanation(
            title: "변동성",
            emoji: "🎢",
            simpleExplanation: "가격이 얼마나 출렁거리는지 보여줘요. 변동성 20%면 1년간 ±20% 움직일 수 있다는 뜻이에요.",
            interpretationGuide: [
                ("15% 이하", "안정적", .Exit.accent),
                ("15~25%", "보통", .Exit.positive),
                ("25~35%", "다소 높음", .Exit.caution),
                ("35% 이상", "높은 변동성", .Exit.warning)
            ],
            tips: nil
        )
    }
    
    /// 배당률 설명 생성
    static func dividendYield(value: Double) -> MetricExplanation {
        MetricExplanation(
            title: "배당률",
            emoji: "💰",
            simpleExplanation: "투자금 대비 매년 받는 배당금 비율이에요. 연간 배당금 ÷ 현재 주가 로 계산해요.",
            interpretationGuide: [
                ("4% 이상", "고배당", .Exit.accent),
                ("2~4%", "적정 배당", .Exit.positive),
                ("1~2%", "저배당", .Exit.caution),
                ("1% 미만", "성장주/무배당", .Exit.secondaryText)
            ],
            tips: value < 0.02 ? [
                "배당 성장률도 함께 확인하세요",
                "배당보다 성장에 집중하는 종목일 수 있어요"
            ] : nil
        )
    }
}

// MARK: - Sector Allocation

/// 섹터별 배분
struct SectorAllocation: Identifiable {
    let id = UUID()
    let sector: String
    let weight: Double
    let emoji: String
    
    var percentage: String {
        String(format: "%.1f%%", weight * 100)
    }
}

// MARK: - Region Allocation

/// 지역별 배분
struct RegionAllocation: Identifiable {
    let id = UUID()
    let region: String
    let flag: String
    let weight: Double
    
    var percentage: String {
        String(format: "%.1f%%", weight * 100)
    }
}

// MARK: - Stock Metric Breakdown

/// 종목별 지표 분석 (CAGR, Sharpe, Volatility, MDD)
struct StockMetricBreakdown: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let emoji: String           // 섹터 이모지
    let value: Double           // 해당 지표 값
    let formattedValue: String  // 포맷된 값 문자열
    let weight: Double          // 포트폴리오 비중
    let contribution: Double    // 가중 기여도
    let isPositive: Bool        // 긍정적 여부 (포트폴리오 평균 대비)
    let rank: Int               // 순위
    
    var formattedContribution: String {
        String(format: "%.2f", contribution * 100)
    }
    
    var weightPercent: String {
        String(format: "%.0f%%", weight * 100)
    }
}

// MARK: - Dividend Stock Breakdown

/// 종목별 배당 분석
struct DividendStockBreakdown: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let emoji: String           // 섹터 이모지
    let weight: Double          // 포트폴리오 비중
    let yield: Double           // 배당률
    let growthRate: Double      // 배당 성장률
    let contribution: Double    // 포트폴리오 배당 기여도
    
    var formattedYield: String {
        String(format: "%.2f%%", yield * 100)
    }
    
    var formattedGrowthRate: String {
        growthRate >= 0 
            ? String(format: "+%.1f%%", growthRate * 100)
            : String(format: "%.1f%%", growthRate * 100)
    }
    
    var weightPercent: String {
        String(format: "%.0f%%", weight * 100)
    }
}

// MARK: - Benchmark Data

/// 벤치마크 지표 (비교군)
struct BenchmarkMetric: Identifiable {
    let id = UUID()
    let name: String
    let ticker: String
    let emoji: String
    let value: Double
    let formattedValue: String
    
    /// S&P500과 미국 단기채권 비교군 예시 데이터 (추후 실제 데이터로 교체)
    enum MetricType {
        case cagr
        case sharpeRatio
        case volatility
        case mdd
    }
    
    /// 지표별 벤치마크 데이터 생성
    static func benchmarks(for type: MetricType) -> [BenchmarkMetric] {
        switch type {
        case .cagr:
            return [
                BenchmarkMetric(
                    name: "S&P 500",
                    ticker: "SPY",
                    emoji: "🇺🇸",
                    value: 0.102,  // 10.2%
                    formattedValue: "10.2%"
                ),
                BenchmarkMetric(
                    name: "미국 단기채권",
                    ticker: "SHY",
                    emoji: "🏦",
                    value: 0.021,  // 2.1%
                    formattedValue: "2.1%"
                )
            ]
        case .sharpeRatio:
            return [
                BenchmarkMetric(
                    name: "S&P 500",
                    ticker: "SPY",
                    emoji: "🇺🇸",
                    value: 0.82,
                    formattedValue: "0.82"
                ),
                BenchmarkMetric(
                    name: "미국 단기채권",
                    ticker: "SHY",
                    emoji: "🏦",
                    value: 0.35,
                    formattedValue: "0.35"
                )
            ]
        case .volatility:
            return [
                BenchmarkMetric(
                    name: "S&P 500",
                    ticker: "SPY",
                    emoji: "🇺🇸",
                    value: 0.182,  // 18.2%
                    formattedValue: "18.2%"
                ),
                BenchmarkMetric(
                    name: "미국 단기채권",
                    ticker: "SHY",
                    emoji: "🏦",
                    value: 0.032,  // 3.2%
                    formattedValue: "3.2%"
                )
            ]
        case .mdd:
            return [
                BenchmarkMetric(
                    name: "S&P 500",
                    ticker: "SPY",
                    emoji: "🇺🇸",
                    value: -0.338,  // -33.8%
                    formattedValue: "-33.8%"
                ),
                BenchmarkMetric(
                    name: "미국 단기채권",
                    ticker: "SHY",
                    emoji: "🏦",
                    value: -0.048,  // -4.8%
                    formattedValue: "-4.8%"
                )
            ]
        }
    }
}

/// 비교 결과 (포트폴리오 vs 벤치마크)
struct BenchmarkComparison {
    let portfolioValue: Double
    let benchmarks: [BenchmarkMetric]
    let isHigherBetter: Bool
    
    /// 포트폴리오가 벤치마크보다 좋은지
    func isBetterThan(_ benchmark: BenchmarkMetric) -> Bool {
        if isHigherBetter {
            return portfolioValue > benchmark.value
        } else {
            return abs(portfolioValue) < abs(benchmark.value)
        }
    }
    
    /// S&P500 대비 상대 성과 (%)
    var relativeToSP500: Double? {
        guard let sp500 = benchmarks.first(where: { $0.ticker == "SPY" }) else { return nil }
        if isHigherBetter {
            return (portfolioValue - sp500.value) / abs(sp500.value)
        } else {
            return (abs(sp500.value) - abs(portfolioValue)) / abs(sp500.value)
        }
    }
}

// MARK: - Data Quality Warning

/// 데이터 품질 경고 정보
struct DataQualityWarning: Identifiable {
    let id = UUID()
    let ticker: String
    let name: String
    let quality: DataQuality
    let message: String
    
    /// 경고 아이콘
    var icon: String {
        switch quality {
        case .reliable, .merged:
            return "checkmark.circle.fill"
        case .limited:
            return "exclamationmark.triangle.fill"
        case .unreliable:
            return "xmark.circle.fill"
        }
    }
    
    /// 경고 색상
    var color: Color {
        switch quality {
        case .reliable:
            return .Exit.positive
        case .merged:
            return .Exit.accent
        case .limited:
            return .Exit.caution
        case .unreliable:
            return .Exit.warning
        }
    }
}

// MARK: - Ticker Merge Info

/// 티커 변경으로 데이터가 병합된 정보
struct TickerMergeInfo: Identifiable {
    let id = UUID()
    let currentTicker: String
    let previousTicker: String
    let changeDate: String?
    
    /// 표시용 문자열
    var displayString: String {
        if let date = changeDate {
            return "\(previousTicker) → \(currentTicker) (\(date))"
        }
        return "\(previousTicker) → \(currentTicker)"
    }
}

