//
//  PortfolioLoadingView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import SwiftUI

/// 포트폴리오 분석 로딩 화면
struct PortfolioLoadingView: View {
    let progress: Double
    let phase: PortfolioAnalysisPhase
    
    var body: some View {
        VStack(spacing: ExitSpacing.xl) {
            Spacer()
            
            // 메인 아이콘 - SF Symbol 로딩 애니메이션
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(Color.Exit.accent)
                .symbolEffect(.bounce, value: progress)
            
            // 제목
            Text("포트폴리오 분석 중")
                .font(.Exit.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.Exit.primaryText)
            
            // 분석 단계
            Text(phase.description)
                .font(.Exit.body)
                .foregroundStyle(Color.Exit.secondaryText)
            
            // 진행률 바
            VStack(spacing: ExitSpacing.sm) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.Exit.divider)
                            .frame(height: 16)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.Exit.accent)
                            .frame(
                                width: geometry.size.width * progress,
                                height: 16
                            )
                            .animation(.easeInOut(duration: 0.2), value: progress)
                    }
                }
                .frame(height: 16)
                
                Text("\(Int(progress * 100))%")
                    .font(.Exit.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.accent)
            }
            .padding(.horizontal, ExitSpacing.xxl)
            
            // 설명
            Text(phase.detail)
                .font(.Exit.caption)
                .foregroundStyle(Color.Exit.secondaryText)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
}

/// 포트폴리오 분석 단계
enum PortfolioAnalysisPhase: Equatable {
    case fetchingData   // 데이터 로드
    case analyzing      // 데이터 분석
    case completed      // 완료
    
    var description: String {
        switch self {
        case .fetchingData:
            return "데이터 로드 중..."
        case .analyzing:
            return "포트폴리오 분석 중..."
        case .completed:
            return "분석 완료!"
        }
    }
    
    var detail: String {
        switch self {
        case .fetchingData:
            return "각 종목의 가격, 배당 데이터를 불러오고 있습니다"
        case .analyzing:
            return "수익률, 변동성, 배분 현황을 분석하고 있습니다"
        case .completed:
            return "분석이 완료되었습니다"
        }
    }
}

#Preview {
    ZStack {
        Color.Exit.background.ignoresSafeArea()
        
        PortfolioLoadingView(
            progress: 0.55,
            phase: .analyzing
        )
    }
    .preferredColorScheme(.dark)
}

