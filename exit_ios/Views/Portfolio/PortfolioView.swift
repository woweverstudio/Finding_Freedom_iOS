//
//  PortfolioView.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  포트폴리오 메인 뷰
//

import SwiftUI
import SwiftData

/// 포트폴리오 탭 메인 뷰
struct PortfolioView: View {
    @State var viewModel: PortfolioViewModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            switch viewModel.viewState {
            case .empty:
                PortfolioEmptyView {
                    viewModel.startEditing()
                }
                
            case .editing:
                PortfolioEditView(viewModel: viewModel)
                
            case .analyzing:
                analyzingView
                
            case .analyzed:
                PortfolioAnalysisView(viewModel: viewModel)
                
            case .error(let message):
                errorView(message: message)
            }
        }
        .onAppear {
            viewModel.configure(with: modelContext)
            if viewModel.allStocks.isEmpty {
                Task {
                    await viewModel.loadInitialData()
                }
            }
        }
    }
    
    // MARK: - Analyzing View
    
    private var analyzingView: some View {
        VStack(spacing: ExitSpacing.lg) {
            Spacer()
            
            // 로딩 애니메이션
            ZStack {
                Circle()
                    .stroke(Color.Exit.divider, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.Exit.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .linear(duration: 1).repeatForever(autoreverses: false),
                        value: viewModel.isLoading
                    )
                
                Text("📊")
                    .font(.system(size: 32))
            }
            
            VStack(spacing: ExitSpacing.sm) {
                Text("포트폴리오 분석 중...")
                    .font(.Exit.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text("종목 데이터를 불러오고 지표를 계산하고 있어요")
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(ExitSpacing.lg)
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: ExitSpacing.lg) {
            Spacer()
            
            Text("😢")
                .font(.system(size: 60))
            
            VStack(spacing: ExitSpacing.sm) {
                Text("오류가 발생했어요")
                    .font(.Exit.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.Exit.primaryText)
                
                Text(message)
                    .font(.Exit.caption)
                    .foregroundStyle(Color.Exit.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                viewModel.backToEdit()
            } label: {
                Text("다시 시도")
                    .font(.Exit.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.Exit.accent)
                    .padding(.horizontal, ExitSpacing.xl)
                    .padding(.vertical, ExitSpacing.md)
                    .background(Color.Exit.accent.opacity(0.15))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(ExitSpacing.lg)
    }
}

// MARK: - Preview

#Preview {
    PortfolioView(viewModel: PortfolioViewModel())
        .modelContainer(for: [UserProfile.self], inMemory: true)
}

