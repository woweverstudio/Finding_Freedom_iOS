//
//  ImageCache.swift
//  exit_ios
//
//  Created by Exit on 2025.
//  이미지 캐싱 서비스 (메모리 + 디스크)
//

import SwiftUI

/// 이미지 캐시 매니저
final class ImageCache {
    
    // MARK: - Singleton
    
    static let shared = ImageCache()
    
    // MARK: - Properties
    
    /// 메모리 캐시
    private let memoryCache = NSCache<NSString, UIImage>()
    
    /// 디스크 캐시 디렉토리
    private let diskCacheDirectory: URL
    
    /// 캐시 유효 기간 (7일)
    private let cacheExpiration: TimeInterval = 7 * 24 * 60 * 60
    
    // MARK: - Initialization
    
    private init() {
        // 메모리 캐시 설정
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // 디스크 캐시 디렉토리 설정
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDirectory = cacheDir.appendingPathComponent("stock_images", isDirectory: true)
        
        // 디렉토리 생성
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        
        // 만료된 캐시 정리
        cleanExpiredCache()
    }
    
    // MARK: - Public Methods
    
    /// 이미지 가져오기 (캐시 → 네트워크)
    func image(for url: URL) async -> UIImage? {
        let key = cacheKey(for: url)
        
        // 1. 메모리 캐시 확인
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }
        
        // 2. 디스크 캐시 확인
        if let diskImage = loadFromDisk(key: key) {
            memoryCache.setObject(diskImage, forKey: key as NSString)
            return diskImage
        }
        
        // 3. 네트워크에서 다운로드
        guard let downloadedImage = await downloadImage(from: url) else {
            return nil
        }
        
        // 캐시에 저장
        memoryCache.setObject(downloadedImage, forKey: key as NSString)
        saveToDisk(image: downloadedImage, key: key)
        
        return downloadedImage
    }
    
    /// 캐시 전체 삭제
    func clearAll() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Private Methods
    
    /// URL에서 캐시 키 생성
    private func cacheKey(for url: URL) -> String {
        // URL에서 apiKey 파라미터 제거 후 해시
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let filteredItems = components?.queryItems?.filter { $0.name != "apiKey" }
        components?.queryItems = filteredItems
        let cleanURL = components?.url?.absoluteString ?? url.absoluteString
        return cleanURL.data(using: .utf8)?.base64EncodedString() ?? url.lastPathComponent
    }
    
    /// 디스크 캐시 경로
    private func diskPath(for key: String) -> URL {
        diskCacheDirectory.appendingPathComponent(key)
    }
    
    /// 디스크에서 이미지 로드
    private func loadFromDisk(key: String) -> UIImage? {
        let path = diskPath(for: key)
        
        guard FileManager.default.fileExists(atPath: path.path) else {
            return nil
        }
        
        // 만료 확인
        if let attributes = try? FileManager.default.attributesOfItem(atPath: path.path),
           let modDate = attributes[.modificationDate] as? Date {
            if Date().timeIntervalSince(modDate) > cacheExpiration {
                try? FileManager.default.removeItem(at: path)
                return nil
            }
        }
        
        guard let data = try? Data(contentsOf: path) else {
            return nil
        }
        
        return UIImage(data: data)
    }
    
    /// 디스크에 이미지 저장
    private func saveToDisk(image: UIImage, key: String) {
        let path = diskPath(for: key)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        try? data.write(to: path)
    }
    
    /// 네트워크에서 이미지 다운로드
    private func downloadImage(from url: URL) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            return UIImage(data: data)
        } catch {
            print("⚠️ Image download failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 만료된 캐시 정리
    private func cleanExpiredCache() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let fileManager = FileManager.default
            guard let files = try? fileManager.contentsOfDirectory(at: self.diskCacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
                return
            }
            
            let now = Date()
            for file in files {
                if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
                   let modDate = attributes[.modificationDate] as? Date {
                    if now.timeIntervalSince(modDate) > self.cacheExpiration {
                        try? fileManager.removeItem(at: file)
                    }
                }
            }
        }
    }
}

