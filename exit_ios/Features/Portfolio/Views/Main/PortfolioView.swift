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
    @Environment(\.appState) private var appState
    @Environment(\.storeService) private var storeService
    
    var body: some View {
        ZStack {
            Color.Exit.background.ignoresSafeArea()
            
            switch viewModel.viewState {
            case .empty:
                emptyScreenView
                
            case .editing:
                editingScreenView
                
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
            // configure에서 loadSavedHoldings가 호출되고, 그 안에서 loadInitialData가 호출됨
            // loadSavedHoldings가 완료되면 holdings가 있으면 자동으로 editing 상태로 변경됨
        }
        .onChange(of: storeService.hasPortfolioAnalysis) { _, hasPurchased in
            // 구입 완료 시 편집 화면으로 이동 (SimulationView와 동일한 로직)
            if hasPurchased && viewModel.viewState == .empty {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.startEditing()
                }
            }
        }
    }
    
    // MARK: - Empty Screen
    
    private var emptyScreenView: some View {
        PortfolioEmptyView(
            onStart: {
                // 이미 구입한 경우 편집 화면으로
                if storeService.hasPortfolioAnalysis {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.startEditing()
                    }
                }
                // 미구입인 경우 EmptyView에서 구입 처리
            },
            isPurchased: storeService.hasPortfolioAnalysis
        )
    }
    
    // MARK: - Editing Screen
    
    private var editingScreenView: some View {
        PortfolioEditView(
            viewModel: viewModel,
            onBack: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    // 분석 결과가 있으면 analyzed로, 없으면 empty로 (SimulationView와 동일한 로직)
                    if viewModel.analysisResult != nil {
                        viewModel.backToAnalyzed()
                    } else {
                        viewModel.backToEmpty()
                    }
                }
            },
            isPurchased: storeService.hasPortfolioAnalysis
        )
        .transition(.move(edge: .trailing))
    }
    
    // MARK: - Analyzing View
    
    private var analyzingView: some View {
        PortfolioLoadingView(
            progress: viewModel.analysisProgress,
            phase: viewModel.analysisPhase
        )
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

