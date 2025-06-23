//
//  MedicineSchedule.swift
//  TermProject_2271246_kimsojin
//
//  Created by 김소진 on 5/25/25.
//

import Foundation

enum Weekday: String, CaseIterable, Codable {
    case sun = "SUN", mon = "MON", tue = "TUE", wed = "WED", thu = "THU", fri = "FRI", sat = "SAT"

        var weekdayNumber: Int {
            switch self {
            case .sun: return 1
            case .mon: return 2
            case .tue: return 3
            case .wed: return 4
            case .thu: return 5
            case .fri: return 6
            case .sat: return 7
            }
        }
}

struct MedicationSchedule: Codable {
    let id: UUID
    var name: String
    var time: Date
    var repeatDays: [Weekday]
    var memo: String
    var isTakenToday: Bool
}

// 오늘 복약 스케줄
struct TodaySchedule {
    let schedule: MedicationSchedule
    var isTaken: Bool
}

extension MedicationSchedule {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    static func fromDictionary(_ dict: [String: Any]) throws -> MedicationSchedule {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return try JSONDecoder().decode(MedicationSchedule.self, from: data)
    }
}
