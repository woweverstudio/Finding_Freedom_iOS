//
//  SimulationEmptyView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 시뮬레이션 초기 화면 (설명 + 시작 버튼)
struct SimulationEmptyView: View {
    let scenario: Scenario?
    let currentAssetAmount: Double
    let onStart: () -> Void
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ExitSpacing.xl) {
                // 아이콘
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.Exit.accent)
                    .padding(.top, ExitSpacing.xxl)
                
                // 제목
                VStack(spacing: ExitSpacing.sm) {
                    Text("몬테카를로 시뮬레이션")
                        .font(.Exit.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.Exit.primaryText)
                    
                    Text("FIRE 달성 확률을 계산합니다")
                        .font(.Exit.body)
                        .foregroundStyle(Color.Exit.secondaryText)
                }
                
                // 설명 카드
                VStack(alignment: .leading, spacing: ExitSpacing.lg) {
                    // 무엇을?
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        HStack(spacing: ExitSpacing.sm) {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundStyle(Color.Exit.accent)
                            Text("몬테카를로 시뮬레이션이란?")
                                .font(.Exit.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.Exit.primaryText)
                        }
                        
                        Text("시장의 불확실성을 반영해 10,000가지 미래를 시뮬레이션합니다. 단순 계산과 달리 \"확률\"로 결과를 보여드립니다.")
                            .font(.Exit.caption)
                            .foregroundStyle(Color.Exit.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Divider()
                        .background(Color.Exit.divider)
                    
                    // 어떤 데이터를?
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        HStack(spacing: ExitSpacing.sm) {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(Color.Exit.accent)
                            Text("사용되는 데이터")
                                .font(.Exit.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.Exit.primaryText)
                        }
                        
                        if let scenario = scenario {
                            VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                                dataRow(label: "현재 자산", value: ExitNumberFormatter.formatToEokManWon(currentAssetAmount))
                                dataRow(label: "월 저축액", value: ExitNumberFormatter.formatToManWon(scenario.monthlyInvestment))
                                dataRow(label: "목표 월수입", value: ExitNumberFormatter.formatToManWon(scenario.desiredMonthlyIncome))
                                dataRow(label: "평균 수익률", value: String(format: "%.1f%%", scenario.preRetirementReturnRate))
                                dataRow(label: "수익률 변동성", value: String(format: "%.1f%%", scenario.returnRateVolatility))
                            }
                        }
                    }
                    
                    Divider()
                        .background(Color.Exit.divider)
                    
                    // 무엇을 볼 수 있나?
                    VStack(alignment: .leading, spacing: ExitSpacing.sm) {
                        HStack(spacing: ExitSpacing.sm) {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(Color.Exit.accent)
                            Text("알 수 있는 것")
                                .font(.Exit.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.Exit.primaryText)
                        }
                        
                        VStack(alignment: .leading, spacing: ExitSpacing.xs) {
                            bulletPoint("FIRE 달성 확률 (73% 같은)")
                            bulletPoint("자산 변화 예측 (3가지 시나리오)")
                            bulletPoint("목표 달성 시점 분포")
                            bulletPoint("최선/평균/최악의 경우")
                        }
                    }
                }
                .padding(ExitSpacing.lg)
                .background(Color.Exit.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: ExitRadius.lg))
                .padding(.horizontal, ExitSpacing.md)
                
                // 시뮬레이션 시작 버튼
                Button {
                    onStart()
                } label: {
                    HStack(spacing: ExitSpacing.sm) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16))
                        Text("시뮬레이션 시작")
                            .font(.Exit.body)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ExitSpacing.md)
                    .background(LinearGradient.exitAccent)
                    .clipShape(RoundedRectangle(cornerRadius: ExitRadius.xl))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, ExitSpacing.md)
                
                Text("약 3~5초 소요됩니다")
                    .font(.Exit.caption2)
                    .foregroundStyle(Color.Exit.tertiaryText)
                
                Spacer()
                    .frame(height: 80)
            }
        }
    }
    
    private func dataRow(label: String, value: String) -> some View {
        HStack {
            Text("• \(label)")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            Spacer()
            Text(value)
                .font(.Exit.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.Exit.primaryText)
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: ExitSpacing.xs) {
            Text("•")
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
            Text(text)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
        }
    }
}

