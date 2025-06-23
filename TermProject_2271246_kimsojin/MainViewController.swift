//
//  ViewController.swift
//  TermProject_2271246_kimsojin
//
//  Created by 김소진 on 5/22/25.
//

import UIKit

class MainViewController: UIViewController {
    private var todaySchedules: [MedicationSchedule] = []
    
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var galleryButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // NotificationCenter 옵저버 등록
        NotificationCenter.default.addObserver(self, selector: #selector(loadTodaySchedule), name: NSNotification.Name("ScheduleUpdated"), object: nil)
        
        titleLabel.textColor = UIColor(named: "MainPurple") ?? UIColor(red: 95/255, green: 61/255, blue: 196/255, alpha: 1)
        
        setupNavigationBar()
        setupButtons()
        setupFeatureButtons()
        
        todayScheduleStackView.spacing = 4
    }
    
    //    override func viewWillAppear(_ animated: Bool) {
    //        super.viewWillAppear(animated)
    //        loadTodaySchedule()
    //    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadTodaySchedule()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ScheduleUpdated"), object: nil)
    }
    
    @objc private func loadTodaySchedule() {
        let weekday = Calendar.current.component(.weekday, from: Date()) // Sunday = 1
        print("오늘 요일 숫자: \(weekday)")
        let userId = ScheduleStorage().deviceId
        
        ScheduleStorage().load(for: userId) {
            allSchedules in
            print("전체 스케줄 개수: \(allSchedules.count)")
            self.todaySchedules = allSchedules.filter { schedule in
                schedule.repeatDays.contains(where: {$0.weekdayNumber == weekday})
            }
            print("오늘 스케줄 개수: \(self.todaySchedules.count)")
            DispatchQueue.main.async {
                guard self.isViewLoaded, self.view.window != nil else {
                    print("View is not ready yet.")
                    return
                }
                self.updateTodayScheduleView()
            }
        }
    }
    
    private func setupNavigationBar() {
        title = "약병 스캐너"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    @IBAction func capturePhotoTapped(_ sender: UIButton) {
        presentImagePicker(sourceType: .camera)
    }
    
    @IBAction func selectFromGalleryTapped(_ sender: UIButton) {
        presentImagePicker(sourceType: .photoLibrary)
    }
    
    @IBOutlet weak var todayScheduleStackView: UIStackView!
    @IBOutlet weak var todaySummaryView: UIView!
    @IBOutlet weak var todaySummaryLabel: UILabel!
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            showAlert(title: "오류", message: "해당 기능을 사용할 수 없습니다.")
            return
        }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = sourceType
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        present(imagePickerController, animated: true)
    }
    
    private func setupFeatureButtons() {
        let features: [(icon: String, title: String, selector: Selector)] = [
            ("calendar.badge.plus", "스케줄 등록", #selector(registerScheduleTapped)),
            ("list.bullet", "스케줄 목록", #selector(viewScheduleListTapped)),
            ("magnifyingglass", "검색 기록", #selector(openHistoryScreen))
        ]
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
        ])
        
        for feature in features {
            let button = UIButton(type: .system)
            button.setTitle("  \(feature.title)", for: .normal)
            button.setImage(UIImage(systemName: feature.icon), for: .normal)
            button.tintColor = .white
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            button.backgroundColor = UIColor(named: "MainPurple") ?? UIColor(red: 177/255, green: 151/255, blue: 252/255, alpha: 1)
            button.layer.cornerRadius = 12
            button.imageView?.contentMode = .scaleAspectFit
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
            
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: -6)
            button.addTarget(self, action: feature.selector, for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }
    
    @objc private func registerScheduleTapped() {
        print("[registerScheduleTapped] 스케줄 등록 버튼 눌림")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nav = storyboard.instantiateViewController(withIdentifier: "ScheduleRegisterNavController") as? UINavigationController {
            print("[registerScheduleTapped] NavigationController 생성 성공")
            present(nav, animated: true)
        } else {
            print("[registerScheduleTapped] NavigationController 생성 실패")
        }
    }
    
    @objc private func viewScheduleListTapped() {
        print("[viewScheduleListTapped] 스케줄 목록 버튼 눌림")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nav = storyboard.instantiateViewController(withIdentifier: "ScheduleListNavController") as? UINavigationController {
            print("[viewScheduleListTapped] NavigationController 생성 성공")
            present(nav, animated: true)
        } else {
            print("[viewScheduleListTapped] NavigationController 생성 실패")
        }
    }
    
    @objc private func openHistoryScreen() {
        print("[openHistoryScreen] 검색 기록 버튼 눌림")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let nav = storyboard.instantiateViewController(withIdentifier: "HistoryNavController") as? UINavigationController {
            print("[openHistoryScreen] NavigationController 생성 성공")
            present(nav, animated: true)
        } else {
            print("[openHistoryScreen] NavigationController 생성 실패")
        }
    }
    
    
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func updateTodayScheduleView() {
        let mainPurple = UIColor(named: "MainPurple") ?? UIColor(red: 95/255, green: 61/255, blue: 196/255, alpha: 1)
        
        guard let stack = self.todayScheduleStackView,
              let summaryLabel = self.todaySummaryLabel,
              let summaryView = self.todaySummaryView else {
            print("todayScheduleStackView 또는 라벨이 아직 nil 상태입니다.")
            return
        }
        
        // 여백 유발하는 서브뷰 제거
            for subview in stack.arrangedSubviews {
                if subview != summaryView {
                    stack.removeArrangedSubview(subview)
                    subview.removeFromSuperview()
                }
            }
        
        // 기존 뷰들을 스택뷰에서 완전히 제거
        stack.arrangedSubviews.forEach {
            stack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        
        if todaySchedules.isEmpty {
            todaySummaryView.isHidden = false
            todaySummaryLabel.text = "오늘 복약할 약이 없습니다."
            
            let emptyLabel = UILabel()
            emptyLabel.text = "스케줄을 등록하면\n이곳에 오늘 복약할 약이 표시돼요!"
            emptyLabel.textColor = .systemGray
            emptyLabel.textAlignment = .center
            emptyLabel.numberOfLines = 0
            emptyLabel.font = UIFont.systemFont(ofSize: 16)
            
            todayScheduleStackView.addArrangedSubview(emptyLabel)
            return
        }
        
        
        todaySummaryView.isHidden = false
        todaySummaryLabel.text = "오늘 복약할 약: \(todaySchedules.count)개"
        
        // 스택뷰로 구성된 요약 뷰에 버튼 추가
        todayScheduleStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
//        for schedule in todaySchedules {
//            let container = UIView()
//            container.translatesAutoresizingMaskIntoConstraints = false
//            
//            let label = UILabel()
//            label.text = "\(schedule.name) - \(formatted(schedule.time))"
//            label.font = UIFont.systemFont(ofSize: 16)
//            label.translatesAutoresizingMaskIntoConstraints = false
//            
//            let button = UIButton(type: .system)
//            button.setTitle(schedule.isTakenToday ? "복용 완료" : "복용하기", for: .normal)
//            button.setTitleColor(.white, for: .normal)
//            button.backgroundColor = schedule.isTakenToday ? .systemGray : mainPurple
//            button.layer.cornerRadius = 6
//            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
//            button.isEnabled = !schedule.isTakenToday
//            button.translatesAutoresizingMaskIntoConstraints = false
//            button.addAction(UIAction(handler: { _ in
//                self.markAsTaken(schedule)
//            }), for: .touchUpInside)
//            
//            container.addSubview(label)
//            container.addSubview(button)
//            
//            NSLayoutConstraint.activate([
//                // Label: 좌측 정렬 + 세로 가운데
//                    label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
//                    label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
//                    
//                    // Button: 우측 정렬 + 세로 가운데
//                    button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
//                    button.centerYAnchor.constraint(equalTo: container.centerYAnchor),
//                    
//                    // 버튼과 라벨 사이 간격
//                    label.trailingAnchor.constraint(lessThanOrEqualTo: button.leadingAnchor, constant: -8),
//                    
//                    // container 높이 고정
//                    container.heightAnchor.constraint(equalToConstant: 36)
//            ])
//            
//            todayScheduleStackView.addArrangedSubview(container)
//        }
        for schedule in todaySchedules {
            let container = UIStackView()
            container.axis = .horizontal
            container.alignment = .center
            container.spacing = 8
            container.distribution = .fill
            container.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.text = "\(schedule.name) - \(formatted(schedule.time))"
            label.font = UIFont.systemFont(ofSize: 16)
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)

            let button = UIButton(type: .system)
            button.setTitle(schedule.isTakenToday ? "복용 완료" : "복용하기", for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = schedule.isTakenToday ? .systemGray : mainPurple
            button.layer.cornerRadius = 6
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            button.isEnabled = !schedule.isTakenToday
            button.addAction(UIAction(handler: { _ in
                self.markAsTaken(schedule)
            }), for: .touchUpInside)
            button.setContentHuggingPriority(.required, for: .horizontal)

            container.addArrangedSubview(label)
            container.addArrangedSubview(button)

            todayScheduleStackView.addArrangedSubview(container)
        }

    }
    
    // 시간 포맷 함수
    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        var selectedImage: UIImage?
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
        }
        
        picker.dismiss(animated: true) {
            if let image = selectedImage {
                self.processSelectedImage(image)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func markAsTaken(_ schedule: MedicationSchedule) {
        var updated = schedule
        updated.isTakenToday = true
        ScheduleStorage().update(updated)
        
        // todaySchedules 내 해당 스케줄도 업데이트
        if let index = todaySchedules.firstIndex(where: { $0.id == schedule.id }) {
            todaySchedules[index] = updated
        }
        
        // UI 즉시 갱신
        updateTodayScheduleView()
        //loadTodaySchedule() // UI 갱신
    }
    
    func setupButtons() {
        configureButton(photoButton, iconName: "camera.fill", title: "약 찍기")
        configureButton(galleryButton, iconName: "photo.fill.on.rectangle.fill", title: "사진 불러오기")
    }
    
    func configureButton(_ button: UIButton, iconName: String, title: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let icon = UIImage(systemName: iconName, withConfiguration: config)
        
        button.setImage(icon, for: .normal)
        button.setTitle("  \(title)", for: .normal) // 아이콘과 텍스트 간격
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = UIColor(named: "MainPurple") ?? UIColor(red: 177/255, green: 151/255, blue: 252/255, alpha: 1)
        button.layer.cornerRadius = 16
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
    }
    
    
    private func processSelectedImage(_ image: UIImage) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let resultVC = storyboard.instantiateViewController(withIdentifier: "ResultViewController") as? ResultViewController {
            resultVC.selectedImage = image
            
            let nav = UINavigationController(rootViewController: resultVC)
            present(nav, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //        if segue.identifier == "showResult",
        //           let resultVC = segue.destination as? ResultViewController,
        //           let image = sender as? UIImage {
        //            resultVC.selectedImage = image
        //        }
    }
}

