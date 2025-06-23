//
//  Models.swift
//  TermProject_2271246_kimsojin
//
//  Created by 김소진 on 5/22/25.
//

import Foundation

struct MedicineInfo: Codable {
    let name: String
    let ingredient: String
    let dosage: String
    let effects: String
    let precautions: String
}

struct DrugAPIResponse: Codable {
    let header: APIHeader?
    let body: DrugAPIResponseBody?
}

struct APIHeader: Codable {
    let resultCode: String
    let resultMsg: String
}

struct DrugAPIResponseBody: Codable {
    let items: [DrugAPIItem]?

    enum CodingKeys: String, CodingKey {
        case items = "items"
    }
}

struct DrugAPIItem: Codable {
    let itemName: String           // 제품명
    let entpName: String?          // 업체명
    let efcyQesitm: String?        // 효능효과
    let useMethodQesitm: String?   // 용법용량
    let atpnQesitm: String?        // 주의사항
}
