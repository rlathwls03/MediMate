//  MedicationScheduleViewController.swift
//  TermProject_2271246_kimsojin

import UIKit

class ScheduleRegisterViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var memoTextView: UITextView!
    @IBOutlet weak var daysStackView: UIStackView!
    @IBOutlet weak var saveButton: UIButton!
    
    private var selectedDays: Set<Weekday> = []
    // 수정할 스케줄
    var scheduleToEdit: MedicationSchedule?
    var prefilledMedicineInfo: MedicineInfo?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDaysButtons()
        timePicker.datePickerMode = .time
        setupKeyboardDismissRecognizer()
        
        // 자동 입력
        if let info = prefilledMedicineInfo {
            nameTextField.text = info.name
        }
        
        nameTextField.layer.cornerRadius = 10
        nameTextField.layer.borderWidth = 1
        nameTextField.layer.borderColor = UIColor.lightGray.cgColor
        
        memoTextView.layer.cornerRadius = 10
        memoTextView.layer.borderWidth = 1
        memoTextView.layer.borderColor = UIColor.systemGray4.cgColor
        
        saveButton.layer.cornerRadius = 12
        saveButton.layer.shadowColor = UIColor.black.cgColor
        saveButton.layer.shadowOpacity = 0.2
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        saveButton.layer.shadowRadius = 4
        
        if let schedule = scheduleToEdit{
            nameTextField.text = schedule.name
            timePicker.date = schedule.time
            memoTextView.text = schedule.memo
            selectedDays = Set(schedule.repeatDays)
            
            // 선택된 요일 버튼 UI도 업데이트
            for view in daysStackView.arrangedSubviews {
                if let button = view as? UIButton,
                   let day = Weekday.allCases.first(where: { $0.rawValue.uppercased() == button.title(for: .normal) }) {
                    if selectedDays.contains(day) {
                        button.backgroundColor = UIColor(named: "MainPurple")
                        button.setTitleColor(.white, for: .normal)
                    }
                    
                }
            }
            saveButton.setTitle("수정", for: .normal)
        }
    }
    private func setupDaysButtons() {
        let mainPurple = UIColor(named: "MainPurple") ?? UIColor(red: 95/255, green: 61/255, blue: 196/255, alpha: 1)
        
        for day in Weekday.allCases {
            let button = UIButton(type: .system)
            button.setTitle(day.rawValue.uppercased(), for: .normal)
            button.setTitleColor(mainPurple, for: .normal)
            button.layer.cornerRadius = 8
            button.layer.borderWidth = 1
            button.layer.borderColor = mainPurple.cgColor
            button.tag = day.hashValue
            button.addTarget(self, action: #selector(dayButtonTapped(_:)), for: .touchUpInside)
            daysStackView.addArrangedSubview(button)
        }
    }
    
    @objc private func dayButtonTapped(_ sender: UIButton) {
        let mainPurple = UIColor(named: "MainPurple") ?? UIColor(red: 95/255, green: 61/255, blue: 196/255, alpha: 1)
        
        guard let day = Weekday.allCases.first(where: { $0.hashValue == sender.tag }) else { return }
        
        if selectedDays.contains(day) {
            selectedDays.remove(day)
            sender.backgroundColor = .clear
            sender.setTitleColor(mainPurple, for: .normal)
        } else {
            selectedDays.insert(day)
            sender.backgroundColor = mainPurple
            sender.setTitleColor(.white, for: .normal)
        }
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(title: "입력 오류", message: "약 이름을 입력해주세요.")
            return
        }
        
        // 수정 모드인 경우
        if var existing = scheduleToEdit {
            existing.name = name
            existing.time = timePicker.date
            existing.memo = memoTextView.text
            existing.repeatDays = Array(selectedDays)
            existing.isTakenToday = false  // 복용 상태 초기화
            
            // 기존 알림 삭제
            let oldIdentifiers = existing.repeatDays.map { "\(existing.id.uuidString)-\($0.rawValue)" }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: oldIdentifiers)
            
            // 파베 업데이트
            ScheduleStorage().update(existing)
            
            // 알림 재등록
            self.scheduleNotification(for: existing)
            self.showAlert(title: "수정 완료", message: "복약 스케줄이 수정되었습니다.") {
                self.navigationController?.popToRootViewController(animated: true)
                
                // pop이 끝난 후에 알림 보내기 (0.4초 뒤에)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    NotificationCenter.default.post(name: NSNotification.Name("ScheduleUpdated"), object: nil)
                }
            }
            return
        }
        
        // 새로 추가하는 경우
        let schedule = MedicationSchedule(
            id: UUID(),
            name: name,
            time: timePicker.date,
            repeatDays: Array(selectedDays),
            memo: memoTextView.text,
            isTakenToday: false
        )
        
        // 저장 호출 추가
        // 기존 데이터 불러와 append
        //        var schedules = ScheduleStorage().load()
        //        schedules.append(schedule)
        ScheduleStorage().save(schedule) { error in
            if let error = error {
                print("Firestore 저장 실패: \(error.localizedDescription)")
                self.showAlert(title: "오류", message: "저장에 실패했어요.\n\(error.localizedDescription)")
            } else {
                print("Firestore 저장 완료")
                self.scheduleNotification(for: schedule)
                self.showAlert(title: "성공", message: "복약 스케줄이 저장되었습니다.") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
                
            }
        }
        
        print("저장된 스케줄:", schedule)
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            alert.dismiss(animated: true) {
                completion?()
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    
    func scheduleNotification(for schedule: MedicationSchedule) {
        for day in schedule.repeatDays {
            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: schedule.time)
            dateComponents.weekday = day.weekdayNumber // Sunday=1, Monday=2, ...
            
            let content = UNMutableNotificationContent()
            content.title = "복약 알림"
            content.body = "\(schedule.name)를 복용할 시간입니다."
            content.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            //            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
            
            
            let request = UNNotificationRequest(
                identifier: "\(schedule.id.uuidString)-\(day.rawValue)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("알림 등록 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupKeyboardDismissRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // 버튼 터치도 인식되도록 설정
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
}
