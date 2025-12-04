//
//  StoreKitService.swift
//  exit_ios
//
//  Created by Exit on 2025.
//

import Foundation
import StoreKit
import Observation

/// StoreKit 2 기반 인앱결제 서비스
@Observable
final class StoreKitService {
    
    // MARK: - Product IDs
    
    enum ProductID: String, CaseIterable {
        case montecarloSimulation = "montecarlo_simulation"
    }
    
    // MARK: - State
    
    /// 로드된 제품들
    private(set) var products: [Product] = []
    
    /// 구매한 제품 ID들
    private(set) var purchasedProductIDs: Set<String> = []
    
    /// 로딩 중 여부
    private(set) var isLoading: Bool = false
    
    /// 에러 메시지
    private(set) var errorMessage: String?
    
    // MARK: - Computed Properties
    
    /// 몬테카를로 시뮬레이션 구입 여부
    var hasMontecarloSimulation: Bool {
        purchasedProductIDs.contains(ProductID.montecarloSimulation.rawValue)
    }
    
    /// 몬테카를로 시뮬레이션 제품
    var montecarloProduct: Product? {
        products.first { $0.id == ProductID.montecarloSimulation.rawValue }
    }
    
    // MARK: - Private
    
    private var updateListenerTask: Task<Void, Error>?
    
    // MARK: - Initialization
    
    init() {
        // 트랜잭션 리스너 시작
        updateListenerTask = listenForTransactions()
        
        // 초기 로드
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// 제품 로드
    @MainActor
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            isLoading = false
        } catch {
            errorMessage = "제품을 불러올 수 없습니다: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// 제품 구매
    @MainActor
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 트랜잭션 검증
                let transaction = try checkVerified(verification)
                
                // 구매 완료 처리
                await transaction.finish()
                await updatePurchasedProducts()
                
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                // 부모 승인 대기 등
                isLoading = false
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "구매에 실패했습니다: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// 몬테카를로 시뮬레이션 구매 (편의 메서드)
    @MainActor
    func purchaseMontecarloSimulation() async -> Bool {
        guard let product = montecarloProduct else {
            errorMessage = "제품을 찾을 수 없습니다"
            return false
        }
        return await purchase(product)
    }
    
    /// 구매 복원
    @MainActor
    func restorePurchases() async {
        isLoading = true
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = "구매 복원에 실패했습니다: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    /// 구매한 제품 업데이트
    @MainActor
    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        
        // 모든 현재 entitlements 확인
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                purchased.insert(transaction.productID)
            } catch {
                // 검증 실패한 트랜잭션은 무시
                continue
            }
        }
        
        purchasedProductIDs = purchased
    }
    
    /// 트랜잭션 리스너
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    await transaction?.finish()
                    await self?.updatePurchasedProducts()
                } catch {
                    // 검증 실패한 트랜잭션은 무시
                    continue
                }
            }
        }
    }
    
    /// 트랜잭션 검증
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Errors

enum StoreError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "트랜잭션 검증에 실패했습니다"
        case .productNotFound:
            return "제품을 찾을 수 없습니다"
        }
    }
}

