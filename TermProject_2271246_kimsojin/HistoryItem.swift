//
//  HistoryItem.swift
//  TermProject_2271246_kimsojin
//
//  Created by 김소진 on 5/22/25.
//

import UIKit

// MARK: - HistoryItem 구조체
struct HistoryItem: Codable {
    let imageData: Data
    let recognizedText: String
    let medicineInfo: MedicineInfo?
    let date: Date
    
    var image: UIImage? {
        return UIImage(data: imageData)
    }
    
    init(image: UIImage, recognizedText: String, medicineInfo: MedicineInfo?, date: Date) {
        self.imageData = image.jpegData(compressionQuality: 0.7) ?? Data()
        self.recognizedText = recognizedText
        self.medicineInfo = medicineInfo
        self.date = date
    }
}

// MARK: - HistoryManager 싱글톤 클래스
class HistoryManager {
    
    static let shared = HistoryManager()
    private let userDefaults = UserDefaults.standard
    private let historyKey = "MedicineHistoryKey"
    private let maxHistoryCount = 50 // 최대 저장 개수
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 히스토리에 새 항목 저장
    func saveToHistory(_ item: HistoryItem) {
        var currentHistory = getHistory()
        
        // 새 항목을 맨 앞에 추가
        currentHistory.insert(item, at: 0)
        
        // 최대 개수 초과시 오래된 항목 제거
        if currentHistory.count > maxHistoryCount {
            currentHistory = Array(currentHistory.prefix(maxHistoryCount))
        }
        
        saveHistory(currentHistory)
    }
    
    /// 전체 히스토리 가져오기
    func getHistory() -> [HistoryItem] {
        guard let data = userDefaults.data(forKey: historyKey) else {
            return []
        }
        
        do {
            let history = try JSONDecoder().decode([HistoryItem].self, from: data)
            return history
        } catch {
            print("히스토리 로드 실패: \(error)")
            return []
        }
    }
    
    /// 특정 인덱스의 히스토리 항목 삭제
    func deleteHistoryItem(at index: Int) {
        var currentHistory = getHistory()
        
        guard index >= 0 && index < currentHistory.count else {
            return
        }
        
        currentHistory.remove(at: index)
        saveHistory(currentHistory)
    }
    
    /// 전체 히스토리 삭제
    func clearAllHistory() {
        userDefaults.removeObject(forKey: historyKey)
    }
    
    /// 히스토리 개수 반환
    func getHistoryCount() -> Int {
        return getHistory().count
    }
    
    // MARK: - Private Methods
    
    private func saveHistory(_ history: [HistoryItem]) {
        do {
            let data = try JSONEncoder().encode(history)
            userDefaults.set(data, forKey: historyKey)
        } catch {
            print("히스토리 저장 실패: \(error)")
        }
    }
}

// MARK: - HistoryManager 확장 기능
extension HistoryManager {
    
    /// 특정 날짜 범위의 히스토리 가져오기
    func getHistory(from startDate: Date, to endDate: Date) -> [HistoryItem] {
        return getHistory().filter { item in
            return item.date >= startDate && item.date <= endDate
        }
    }
    
    /// 특정 약물명으로 히스토리 검색
    func searchHistory(by medicineName: String) -> [HistoryItem] {
        return getHistory().filter { item in
            return item.medicineInfo?.name.lowercased().contains(medicineName.lowercased()) ?? false
        }
    }
    
    /// 전체 히스토리 덮어쓰기 (예: 순서 변경 후)
    func setHistory(_ items: [HistoryItem]) {
        saveHistory(items)
    }
    
    /// 히스토리 통계 정보
    func getHistoryStatistics() -> (totalCount: Int, medicineNames: [String], recentSearchDate: Date?) {
        let history = getHistory()
        let medicineNames = history.compactMap { $0.medicineInfo?.name }
        let recentDate = history.first?.date
        
        return (
            totalCount: history.count,
            medicineNames: Array(Set(medicineNames)), // 중복 제거
            recentSearchDate: recentDate
        )
    }
}
