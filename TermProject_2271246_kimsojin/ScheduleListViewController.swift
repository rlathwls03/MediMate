//
//  ScheduleListViewController.swift
//  TermProject_2271246_kimsojin
//
//  Created by 김소진 on 5/25/25.
//

import UIKit

class ScheduleListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!

    private var schedules: [MedicationSchedule] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // 일회성 전체 삭제
//            UserDefaults.standard.removeObject(forKey: "medicationSchedules")
            
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 70
        navigationItem.leftBarButtonItem = editButtonItem
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let userId = ScheduleStorage().deviceId  // ← 저장할 때 사용한 ID와 동일하게
            ScheduleStorage().load(for: userId) { loadedSchedules in
                self.schedules = loadedSchedules
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedules.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath)
        let schedule = schedules[indexPath.row]
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        cell.textLabel?.text = "\(schedule.name) - \(formatter.string(from: schedule.time))"
        cell.detailTextLabel?.text = "반복: \(schedule.repeatDays.map { $0.rawValue }.joined(separator: ", "))"
        return cell
    }
    
    // 삭제 가능 여부
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // 삭제 처리
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let deletedSchedule = schedules.remove(at: indexPath.row)
            ScheduleStorage().delete(deletedSchedule) { error in
                if let error = error {
                    print("삭제 실패: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                }
            }
        }
    }
    
    // 이동 가능 여부
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // 이동 처리
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let moved = schedules.remove(at: sourceIndexPath.row)
        schedules.insert(moved, at: destinationIndexPath.row)
//        ScheduleStorage().save(schedules)
    }
    
    // 셀 클릭 시 이동
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = schedules[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let registerVC = storyboard.instantiateViewController(withIdentifier: "ScheduleRegisterViewController") as? ScheduleRegisterViewController {
            registerVC.scheduleToEdit = selected
            navigationController?.pushViewController(registerVC, animated: true)
        }
    }

}

