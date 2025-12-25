//
//  StockLogoImage.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  종목 로고 이미지 컴포넌트
//

import SwiftUI

/// 종목 로고 이미지 뷰
struct StockLogoImage: View {
    let ticker: String
    let iconUrl: String?
    let size: CGFloat
    
    /// API Key가 추가된 아이콘 URL
    private var imageURL: URL? {
        guard let urlString = iconUrl, !urlString.isEmpty else {
            return nil
        }
        
        let apiKey = AppConfig.polygonAPIKey
        return URL(string: "\(urlString)?apiKey=\(apiKey)")
    }
    
    /// 첫 글자에 따른 배경 색상 (빨주노초파남보)
    private var placeholderColor: Color {
        guard let firstChar = ticker.uppercased().first,
              let asciiValue = firstChar.asciiValue else {
            return .gray
        }
        
        // A(65) ~ Z(90) 범위를 7색으로 매핑
        let index = Int(asciiValue - 65) % 7
        
        let colors: [Color] = [
            Color(red: 0.90, green: 0.25, blue: 0.30),  // 빨강
            Color(red: 0.65, green: 0.35, blue: 0.80),  // 보라
            Color(red: 0.95, green: 0.50, blue: 0.20),  // 주황
            Color(red: 0.90, green: 0.75, blue: 0.20),  // 노랑
            Color(red: 0.30, green: 0.75, blue: 0.45),  // 초록
            Color(red: 0.25, green: 0.55, blue: 0.90),  // 파랑
            Color(red: 0.35, green: 0.35, blue: 0.75),  // 남색            
        ]
        
        return colors[max(0, min(index, colors.count - 1))]
    }
    
    var body: some View {
        if let url = imageURL {
            CachedAsyncImage(url: url, size: size) {
                placeholderView
            }
        } else {
            placeholderView
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(placeholderColor)
            
            Text(ticker)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(.white)
                .padding(4)
        }
        .frame(width: size, height: size)
    }
}

/// 캐싱이 적용된 AsyncImage
struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL
    let size: CGFloat
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if isLoading {
                ProgressView()
                    .frame(width: size, height: size)
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        isLoading = true
        image = await ImageCache.shared.image(for: url)
        isLoading = false
    }
}

#Preview {
    VStack(spacing: 16) {
        // 빨주노초파남보 색상 확인
        HStack(spacing: 12) {
            StockLogoImage(ticker: "AAPL", iconUrl: nil, size: 48)  // A: 빨강
            StockLogoImage(ticker: "HOOD", iconUrl: nil, size: 48)  // H: 주황
            StockLogoImage(ticker: "INTC", iconUrl: nil, size: 48)  // I: 노랑
            StockLogoImage(ticker: "PLTR", iconUrl: nil, size: 48)  // P: 초록
        }
        HStack(spacing: 12) {
            StockLogoImage(ticker: "QQQM", iconUrl: nil, size: 48)  // Q: 파랑
            StockLogoImage(ticker: "SCHD", iconUrl: nil, size: 48)  // S: 파랑
            StockLogoImage(ticker: "XPEV", iconUrl: nil, size: 48)  // X: 남색
            StockLogoImage(ticker: "YINN", iconUrl: nil, size: 48)  // Y: 보라
        }
    }
    .padding()
    .background(Color.Exit.background)
}
