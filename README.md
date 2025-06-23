# 📱 약병 스캐너 (Smart Pill Reminder)

## 👩‍⚕️ 소개
**약병 스캐너**는 사용자가 약을 복용하는 시간을 잊지 않도록 돕는 iOS 앱입니다.  
카메라 또는 갤러리에서 약병을 촬영하면, **OCR(Apple Vision)** 기술을 활용하여 약 이름과 성분을 자동 인식하고,  
**공공 API(e약은요)**를 통해 상세한 복약 정보를 제공합니다.

---

## 💡 주요 기능

| 기능 | 설명 |
|------|------|
| 📷 이미지 OCR | 약 이름이 보이는 사진을 찍으면 텍스트 자동 인식 |
| 🧠 키워드 추출 | 텍스트에서 약 이름 및 성분 후보를 필터링하여 후보 리스트 생성 |
| 🔍 약 정보 검색 | `e약은요 API`를 통해 약의 복용법, 효능, 주의사항 등을 제공 |
| 📅 복약 스케줄 관리 | 요일 반복, 시간 설정, 메모 포함 스케줄 등록 기능 |
| 🔔 알림 기능 | 설정된 시간에 복약 알림 전송 (앱 내 표시 중심) |
| ✅ 복용 체크 | 복용 완료 여부를 하루 단위로 관리 |
| 🕓 검색 이력 저장 | 사진과 인식된 정보 및 약 정보를 기록하고 재확인 가능 |

---

## 🔧 기술 스택

- **iOS (UIKit, Storyboard)**
- **Apple Vision Framework** – 텍스트 인식 (OCR)
- **Firebase Firestore** – 약 정보 저장 및 캐싱
- **e약은요 공공 API** – 약물 상세 정보 조회
- **UserDefaults (JSON)** – 복약 스케줄 로컬 저장

---

## 프로젝트 구조

```
📁 TermProject_2271246_kimsojin
├── 📁 ViewController
│   ├── MainViewController.swift
│   ├── ResultViewController.swift
│   ├── ScheduleRegisterViewController.swift
│   └── HistoryViewController.swift
├── 📁 Model
│   ├── MedicationSchedule.swift
│   ├── MedicineInfo.swift
│   └── HistoryItem.swift
├── 📁 Utils
│   └── ScheduleStorage.swift
└── 📁 Assets / Storyboard / Info.plist 등
```
---
