//
//  HistoryViewController.swift
//  TermProject_2271246_kimsojin
//
//  Created by 김소진 on 5/22/25.
//

import UIKit

class HistoryViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var historyItems: [HistoryItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadHistoryData()
        navigationItem.leftBarButtonItem = editButtonItem
        
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadHistoryData()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 100
    }
    
    private func loadHistoryData() {
        historyItems = HistoryManager.shared.getHistory()
        tableView.reloadData()
        
        if historyItems.isEmpty {
            showEmptyState()
        }
    }
    
    private func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "검색 기록이 없습니다.\n약병을 스캔해보세요!"
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.textColor = .systemGray
        emptyLabel.font = UIFont.systemFont(ofSize: 18)
        
        tableView.backgroundView = emptyLabel
    }
}

// MARK: - UITableViewDataSource
extension HistoryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as? HistoryTableViewCell else {
            return UITableViewCell()
        }
        
        let historyItem = historyItems[indexPath.row]
        cell.configure(with: historyItem)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedItem = historyItems.remove(at: sourceIndexPath.row)
        historyItems.insert(movedItem, at: destinationIndexPath.row)
        HistoryManager.shared.setHistory(historyItems) // 저장소에도 반영
    }
    
    // 스와이프 삭제 비활성화
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return isEditing ? .delete : .none
    }
    
}

// MARK: - UITableViewDelegate
extension HistoryViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let historyItem = historyItems[indexPath.row]
        showHistoryDetail(historyItem)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 항목 삭제
            HistoryManager.shared.deleteHistoryItem(at: indexPath.row)
            historyItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            if historyItems.isEmpty {
                showEmptyState()
            }
        }
    }
    
    private func showHistoryDetail(_ historyItem: HistoryItem) {
        let alert = UIAlertController(
            title: "스케줄 등록",
            message: "이 약으로 복약 스케줄을 등록하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "약 정보", style: .cancel, handler: { _ in
            self.navigateToResultView(with: historyItem) // 취소 시에도 결과 화면으로 이동
        }))
        alert.addAction(UIAlertAction(title: "알림설정", style: .default, handler: { _ in
            self.navigateToScheduleRegister(with: historyItem.medicineInfo)
        }))
        present(alert, animated: true)
        
        //        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //        if let resultVC = storyboard.instantiateViewController(withIdentifier: "ResultViewController") as? ResultViewController {
        //            resultVC.selectedImage = historyItem.image
        //            resultVC.recognizedText = historyItem.recognizedText
        //            resultVC.medicineInfo = historyItem.medicineInfo
        //            resultVC.hidesBottomBarWhenPushed = true
        //            navigationController?.pushViewController(resultVC, animated: true)
        //        }
    }
    
    private func navigateToResultView(with historyItem: HistoryItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let resultVC = storyboard.instantiateViewController(withIdentifier: "ResultViewController") as? ResultViewController {
            resultVC.selectedImage = historyItem.image
            resultVC.recognizedText = historyItem.recognizedText
            resultVC.medicineInfo = historyItem.medicineInfo
            resultVC.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(resultVC, animated: true)
        }
    }
    
    
    private func navigateToScheduleRegister(with info: MedicineInfo?) {
        guard let info = info else {
            self.showAlert(title: "정보 없음", message: "약물 정보가 없습니다.")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let registerVC = storyboard.instantiateViewController(withIdentifier: "ScheduleRegisterViewController") as? ScheduleRegisterViewController {
            registerVC.prefilledMedicineInfo = info
            self.navigationController?.pushViewController(registerVC, animated: true)
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
}

// MARK: - HistoryTableViewCell
class HistoryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var medicineImageView: UIImageView!
    @IBOutlet weak var medicineNameLabel: UILabel!
    @IBOutlet weak var recognizedTextLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    func configure(with historyItem: HistoryItem) {
        medicineImageView.image = historyItem.image
        medicineImageView.contentMode = .scaleAspectFill
        medicineImageView.clipsToBounds = true
        medicineImageView.layer.cornerRadius = 8
        
        medicineNameLabel.text = historyItem.medicineInfo?.name ?? "약물 정보 없음"
        
        // 인식된 텍스트를 짧게 표시 (최대 50자)
        let displayText = historyItem.recognizedText.count > 50
        ? String(historyItem.recognizedText.prefix(50)) + "..."
        : historyItem.recognizedText
        recognizedTextLabel.text = displayText.isEmpty ? "인식된 텍스트 없음" : displayText
        
        // 날짜 포맷팅
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        dateLabel.text = formatter.string(from: historyItem.date)
    }
}
