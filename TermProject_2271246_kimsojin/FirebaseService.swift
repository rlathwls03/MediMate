//
//  FirebaseService.swift
//  TermProject_2271246_kimsojin
//
//  Created by 김소진 on 5/22/25.
//

import Foundation
import Firebase
import FirebaseFirestore

class FirebaseService {
    
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func uploadNewMedicine(_ medicine: [String: Any]) {
        db.collection("medications").addDocument(data: medicine) { error in
            if let error = error {
                print("새 약물 업로드 실패: \(error)")
            } else {
                print("새 약물 업로드 성공: \(medicine["name"] ?? "이름 없음")")
            }
        }
    }

    // MARK: - 샘플 데이터 업로드 (초기 설정용)
    func uploadSampleMedicineData() {
        let sampleMedicines: [[String: Any]] = [
            [
                "name": "타이레놀",
                "ingredient": "아세트아미노펜",
                "dosage": "500mg",
                "effects": "해열, 진통",
                "precautions": "간 질환자 주의, 하루 최대 4g"
            ],
            [
                "name": "애드빌",
                "ingredient": "이부프로펜",
                "dosage": "200mg",
                "effects": "소염, 진통, 해열",
                "precautions": "위장장애 주의, 식후 복용"
            ],
            [
                "name": "게보린",
                "ingredient": "아스피린+카페인",
                "dosage": "500mg+30mg",
                "effects": "두통, 치통, 생리통 완화",
                "precautions": "16세 이하 복용 금지"
            ],
            [
                "name": "펜잘큐",
                "ingredient": "이부프로펜",
                "dosage": "200mg",
                "effects": "생리통, 두통, 근육통",
                "precautions": "임신 3기 복용 금지"
            ],
            [
                "name": "낙센",
                "ingredient": "낙센",
                "dosage": "275mg",
                "effects": "소염, 진통",
                "precautions": "위궤양 환자 주의"
            ],
            [
                "name": "어린이타이레놀",
                "ingredient": "아세트아미노펜",
                "dosage": "80mg",
                "effects": "소아 해열, 진통",
                "precautions": "체중에 따른 용량 조절"
            ],
            [
                "name": "탁센",
                "ingredient": "아세트아미노펜+카페인",
                "dosage": "500mg+30mg",
                "effects": "두통, 치통, 근육통",
                "precautions": "카페인 과다섭취 주의"
            ],
            [
                "name": "브루펜",
                "ingredient": "이부프로펜",
                "dosage": "400mg",
                "effects": "관절염, 근육통, 염좌",
                "precautions": "신장 질환자 주의"
            ]
        ]
        
        for medicine in sampleMedicines {
            db.collection("medications").addDocument(data: medicine) { error in
                if let error = error {
                    print("데이터 업로드 실패: \(error)")
                } else {
                    print("약물 데이터 업로드 성공: \(medicine["name"] ?? "")")
                }
            }
        }
    }
    
    // MARK: - 약물 정보 검색
    func searchMedicine(by name: String, completion: @escaping (Result<MedicineInfo?, Error>) -> Void) {
        db.collection("medications")
            .whereField("name", isGreaterThanOrEqualTo: name)
            .whereField("name", isLessThan: name + "\u{f8ff}")
            .getDocuments { querySnapshot, error in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = querySnapshot?.documents,
                      let firstDocument = documents.first else {
                    completion(.success(nil))
                    return
                }
                
                let data = firstDocument.data()
                let medicineInfo = MedicineInfo(
                    name: data["name"] as? String ?? "",
                    ingredient: data["ingredient"] as? String ?? "",
                    dosage: data["dosage"] as? String ?? "",
                    effects: data["effects"] as? String ?? "",
                    precautions: data["precautions"] as? String ?? ""
                )
                
                completion(.success(medicineInfo))
            }
    }
    
    // MARK: - 키워드로 약물 검색
    func searchMedicineByKeywords(_ keywords: [String], completion: @escaping (Result<MedicineInfo?, Error>) -> Void) {
        guard !keywords.isEmpty else {
            completion(.success(nil))
            return
        }
        
        // 첫 번째 키워드로 검색 시작
        searchByKeyword(keywords, index: 0, completion: completion)
    }
    
    private func searchByKeyword(_ keywords: [String], index: Int, completion: @escaping (Result<MedicineInfo?, Error>) -> Void) {
        guard index < keywords.count else {
            completion(.success(nil))
            return
        }
        
        let keyword = keywords[index]
        
        db.collection("medications")
            .whereField("name", isGreaterThanOrEqualTo: keyword)
            .whereField("name", isLessThan: keyword + "\u{f8ff}")
            .getDocuments { [weak self] querySnapshot, error in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let documents = querySnapshot?.documents,
                   let firstDocument = documents.first {
                    
                    let data = firstDocument.data()
                    let medicineInfo = MedicineInfo(
                        name: data["name"] as? String ?? "",
                        ingredient: data["ingredient"] as? String ?? "",
                        dosage: data["dosage"] as? String ?? "",
                        effects: data["effects"] as? String ?? "",
                        precautions: data["precautions"] as? String ?? ""
                    )
                    
                    completion(.success(medicineInfo))
                    return
                }
                
                // 2차: ingredient 필드로 검색
                self?.db.collection("medications")
                    .whereField("ingredient", isGreaterThanOrEqualTo: keyword)
                    .whereField("ingredient", isLessThan: keyword + "\u{f8ff}")
                    .getDocuments { querySnapshot2, error2 in
                        
                        if let error2 = error2 {
                            completion(.failure(error2))
                            return
                        }
                        
                        if let documents = querySnapshot2?.documents, let firstDocument = documents.first {
                            let data = firstDocument.data()
                            let medicineInfo = MedicineInfo(
                                name: data["name"] as? String ?? "",
                                ingredient: data["ingredient"] as? String ?? "",
                                dosage: data["dosage"] as? String ?? "",
                                effects: data["effects"] as? String ?? "",
                                precautions: data["precautions"] as? String ?? ""
                            )
                            completion(.success(medicineInfo))
                            return
                        }
                        
                        // 둘 다 실패 → 다음 키워드로
                        self?.searchByKeyword(keywords, index: index + 1, completion: completion)
                    }
            }
    }
    
    // MARK: - 모든 약물 리스트 가져오기
    func getAllMedicines(completion: @escaping (Result<[MedicineInfo], Error>) -> Void) {
        db.collection("medications").getDocuments { querySnapshot, error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let medicines = documents.compactMap { document -> MedicineInfo? in
                let data = document.data()
                return MedicineInfo(
                    name: data["name"] as? String ?? "",
                    ingredient: data["ingredient"] as? String ?? "",
                    dosage: data["dosage"] as? String ?? "",
                    effects: data["effects"] as? String ?? "",
                    precautions: data["precautions"] as? String ?? ""
                )
            }
            
            completion(.success(medicines))
        }
    }
}
