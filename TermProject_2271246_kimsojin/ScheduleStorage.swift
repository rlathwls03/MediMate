//
//  ScheduleStorage.swift
//  TermProject_2271246_kimsojin
//
//  Created by 김소진 on 5/25/25.
//

import Foundation
import FirebaseFirestore

class ScheduleStorage {
    private let db = Firestore.firestore()
    private let collection = "medicationSchedules"

    // 기기 고유 ID 생성 (앱 설치 후 유지)
    var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: "deviceId") {
            return existing
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "deviceId")
            return newId
        }
    }

    
    func save(_ schedule: MedicationSchedule, completion: ((Error?) -> Void)? = nil) {
           let docRef = db.collection(collection).document(deviceId).collection("schedules").document(schedule.id.uuidString)
           do {
               let data = try schedule.toDictionary()
               docRef.setData(data, completion: completion)
           } catch {
               completion?(error)
           }
       }

    func load(for userId: String, completion: @escaping ([MedicationSchedule]) -> Void) {
        db.collection(collection).document(userId).collection("schedules").getDocuments { snapshot, error in
            if let documents = snapshot?.documents {
                let schedules: [MedicationSchedule] = documents.compactMap {
                    try? MedicationSchedule.fromDictionary($0.data())
                }
                completion(schedules)
            } else {
                completion([])
            }
        }
    }

    func delete(_ schedule: MedicationSchedule, completion: ((Error?) -> Void)? = nil) {
        db.collection(collection)
          .document(deviceId)
          .collection("schedules")
          .document(schedule.id.uuidString)
          .delete(completion: completion)
    }

    func deleteAll(for userId: String) {
        db.collection(collection).document(userId).collection("schedules").getDocuments { snapshot, _ in
            snapshot?.documents.forEach { $0.reference.delete() }
        }
    }
    
    func update(_ updatedSchedule: MedicationSchedule) {
        let docRef = db.collection(collection)
            .document(deviceId)
            .collection("schedules")
            .document(updatedSchedule.id.uuidString)
        
        do {
            let data = try updatedSchedule.toDictionary()
            docRef.setData(data) { error in
                if let error = error {
                    print("스케줄 업데이트 실패: \(error.localizedDescription)")
                } else {
                    print("스케줄 업데이트 완료")
                }
            }
        } catch {
            print("스케줄 딕셔너리 변환 실패: \(error.localizedDescription)")
        }
    }

}
