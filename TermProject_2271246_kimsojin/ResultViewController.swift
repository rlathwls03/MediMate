//
//  ResultViewController.swift
//  TermProject_2271246_kimsojin
//

import UIKit
import Vision
import Firebase
import FirebaseFirestore

class ResultViewController: UIViewController {

    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var recognizedTextView: UITextView!
    @IBOutlet weak var medicineNameLabel: UILabel!
    @IBOutlet weak var ingredientLabel: UILabel!
    @IBOutlet weak var dosageLabel: UILabel!
    @IBOutlet weak var effectsLabel: UILabel!
    @IBOutlet weak var precautionsLabel: UILabel!

    var selectedImage: UIImage?
    var recognizedText: String?
    var medicineInfo: MedicineInfo?
    let mainPurple = UIColor(named: "MainPurple") ?? UIColor(red: 95/255, green: 61/255, blue: 196/255, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "재검색",
            style: .plain,
            target: self,
            action: #selector(retrySearchTapped(_:))
        )
        navigationItem.rightBarButtonItem?.tintColor = mainPurple
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        if let text = recognizedText, !text.isEmpty {
            recognizedTextView.text = text
        }

        if let info = medicineInfo {
            updateMedicineInfo(info)
        } else if let image = selectedImage {
            processImage(image)
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setupUI() {
        capturedImageView.image = selectedImage
        capturedImageView.layer.cornerRadius = 10
        capturedImageView.clipsToBounds = true

        recognizedTextView.isEditable = true
        recognizedTextView.layer.borderColor = UIColor.systemGray4.cgColor
        recognizedTextView.layer.borderWidth = 1.0
        recognizedTextView.layer.cornerRadius = 8.0
    }

    private func processImage(_ image: UIImage) {
        showLoadingAlert()

        guard let cgImage = image.cgImage else {
            hideLoadingAlert()
            showAlert(title: "오류", message: "이미지를 분석할 수 없습니다.")
            return
        }

        let request = VNRecognizeTextRequest { [weak self] (request, error) in
            DispatchQueue.main.async {
                self?.hideLoadingAlert()
            }

            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "오류", message: "텍스트 인식 실패: \(error.localizedDescription)")
                }
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "오류", message: "텍스트 결과 없음")
                }
                return
            }

            let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = recognizedStrings.joined(separator: "\n")

            DispatchQueue.main.async {
                self?.recognizedText = fullText
                self?.recognizedTextView.text = fullText
                let keywordTuple = self?.extractKeywords(from: fullText) ?? ([], [])
                self?.searchMedicineInfo(from: fullText)
            }
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ko-KR", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.hideLoadingAlert()
                    self.showAlert(title: "오류", message: "Vision 요청 실패: \(error.localizedDescription)")
                }
            }
        }
    }

//    private func searchMedicineInfo(with keywords: [String]) {
//        print("Firebase에서 검색 시도 중: \(keywords)")
//        let db = Firestore.firestore()
//        let group = DispatchGroup()
//        var foundInfo: MedicineInfo?
//
//        for keyword in keywords {
//            group.enter()
//            db.collection("medications")
//                .whereField("name", isGreaterThanOrEqualTo: keyword)
//                .whereField("name", isLessThan: keyword + "\u{f8ff}")
//                .getDocuments { querySnapshot, error in
//                    if let documents = querySnapshot?.documents, let data = documents.first?.data() {
//                        foundInfo = MedicineInfo(
//                            name: data["name"] as? String ?? "정보 없음",
//                            ingredient: data["ingredient"] as? String ?? "정보 없음",
//                            dosage: data["dosage"] as? String ?? "정보 없음",
//                            effects: data["effects"] as? String ?? "정보 없음",
//                            precautions: data["precautions"] as? String ?? "정보 없음"
//                        )
//                    }
//                    group.leave()
//                }
//        }
//
//        group.notify(queue: .main) {
//            if let info = foundInfo {
//                self.medicineInfo = info
//                self.updateMedicineInfo(info)
//            } else {
//                let meaningful = keywords.filter {
//                    $0.count >= 2 && !["SINCE", "품", "3", "일", "도기", "동화약", "30캡슐", "효과", "빠른", "액상형"].contains($0)
//                }
//                let searchCandidates = self.generateCombinedKeywords(from: meaningful)
//                self.searchFallbackWithAPI(keywords: searchCandidates)
//            }
//        }
    
    private func searchMedicineInfo(from text: String) {
        let (names, ingredients) = extractKeywords(from: text)
        print("약물명 후보: \(names)")
        print("성분 후보: \(ingredients)")

        if !names.isEmpty {
            trySearchAPISequentially(keywords: names, fallbackKeywords: ingredients)
        } else if !ingredients.isEmpty {
            trySearchAPISequentially(keywords: ingredients, fallbackKeywords: [])
        } else {
            showNoResultsFound()
        }
    }

    private func trySearchAPISequentially(keywords: [String], fallbackKeywords: [String], index: Int = 0) {
        if index >= keywords.count {
              if !fallbackKeywords.isEmpty {
                  print("이름 실패 → 성분으로 재검색 시작")
                  trySearchAPISequentially(keywords: fallbackKeywords, fallbackKeywords: [], index: 0)
              } else {
                  print("API 실패 → 로컬 키워드로도 결과 없음")
                  showNoResultsFound()
              }
              return
          }

        let keyword = keywords[index]
        print("API 요청 중: \(keyword)")

        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let serviceKey = "OvVzOHt0MH6FSFfOCusdihqnTQcEBJ7mNwYIwUTlGF%2FAz8xchy89OU0q12WYYpqMun8abA%2F2baEdSEDK8qIYfQ%3D%3D"
        let urlString = "https://apis.data.go.kr/1471000/DrbEasyDrugInfoService/getDrbEasyDrugList?serviceKey=\(serviceKey)&itemName=\(encodedKeyword)&type=json&pageNo=1&numOfRows=10"

        guard let url = URL(string: urlString) else {
            trySearchAPISequentially(keywords: keywords, fallbackKeywords: fallbackKeywords, index: index + 1)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                self.trySearchAPISequentially(keywords: keywords, fallbackKeywords: fallbackKeywords, index: index + 1)
                return
            }

            do {
                let jsonString = String(data: data, encoding: .utf8) ?? "null"
                    print("응답 JSON: \(jsonString)")
                let decoded = try JSONDecoder().decode(DrugAPIResponse.self, from: data)
                print("디코딩 성공: \(decoded)")
                
                if let item = decoded.body?.items?.first {
                    let info = MedicineInfo(
                        name: item.itemName,
                                ingredient: item.entpName ?? "정보 없음",
                                dosage: item.useMethodQesitm ?? "정보 없음",
                                effects: item.efcyQesitm ?? "정보 없음",
                                precautions: item.atpnQesitm ?? "정보 없음"
                    )
                    DispatchQueue.main.async {
                        self.medicineInfo = info
                        self.updateMedicineInfo(info)
                    }
                } else {
                    print("응답은 왔지만 items가 비어 있음")
                    self.trySearchAPISequentially(keywords: keywords, fallbackKeywords: fallbackKeywords, index: index + 1)
                }
            } catch {
                print("JSON 디코딩 실패: \(error.localizedDescription)")
                let raw = String(data: data, encoding: .utf8) ?? "No data"
                    print("디코딩 실패한 원본 JSON: \(raw)")
                self.trySearchAPISequentially(keywords: keywords, fallbackKeywords: fallbackKeywords, index: index + 1)
            }
        }.resume()
    }

    
    private func generateCombinedKeywords(from words: [String]) -> [String] {
        let important = words.filter {
            !$0.contains("효과") && !$0.contains("일반의") &&
            !$0.contains("소염진통제") && !$0.contains("30캡슐") &&
            !$0.contains("생리통에") && !$0.contains("대웅제약")
        }

        var results: Set<String> = Set(important)
        let maxCombo = min(3, important.count)

        for length in 2...maxCombo {
            let permutations = important.combinations(ofCount: length)
            for combo in permutations {
                results.insert(combo.joined())
            }
        }

        return Array(results).sorted { $0.count > $1.count }
    }

    private func searchFallbackWithAPI(keywords: [String]) {
        let blacklist = ["SINCE", "품", "3", "일", "도기", "동화약", "30캡슐", "효과", "빠른", "액상형"]
        let filtered = keywords.filter { $0.count >= 2 && !blacklist.contains($0) }
        trySearchAPIRecursive(index: 0, keywords: filtered)
    }

    private func trySearchAPIRecursive(index: Int, keywords: [String]) {
        guard index < keywords.count else {
            print("API 실패 → 로컬 키워드로도 결과 없음")
            showNoResultsFound()
            showNoResultsFound()
            return
        }

        let keyword = keywords[index]
        print("공공 API 요청 중: \(keyword)")
        let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let serviceKey = "OvVzOHt0MH6FSFfOCusdihqnTQcEBJ7mNwYIwUTlGF/Az8xchy89OU0q12WYYpqMun8abA/2baEdSEDK8qIYfQ=="
        let encodedKey = serviceKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://apis.data.go.kr/1471000/DrugPrdtPrmsnInfoService06/getDrugPrdtPrmsnInq06?serviceKey=\(encodedKey)&item_name=\(encodedKeyword)&type=json&pageNo=1&numOfRows=100"

        guard let url = URL(string: urlString) else {
            trySearchAPIRecursive(index: index + 1, keywords: keywords)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                self.trySearchAPIRecursive(index: index + 1, keywords: keywords)
                return
            }

            do {
                let decoded = try JSONDecoder().decode(DrugAPIResponse.self, from: data)
                if let item = decoded.body?.items?.first(where: { $0.itemName.contains(keyword) }) {
                    let info = MedicineInfo(
                        name: item.itemName,
                        ingredient: item.entpName ?? "정보 없음",
                        dosage: item.useMethodQesitm ?? "정보 없음",
                        effects: item.efcyQesitm ?? "정보 없음",
                        precautions: item.atpnQesitm ?? "정보 없음"
                    )

                    DispatchQueue.main.async {
                        self.medicineInfo = info
                        self.updateMedicineInfo(info)
                    }
                } else {
                    let nextIndex = index + 1
                    if nextIndex < keywords.count {
                        self.trySearchAPIRecursive(index: nextIndex, keywords: keywords)
                    } else {
                        print("API 실패 → 로컬 키워드로도 결과 없음")
                        self.showNoResultsFound()
                    }
                }
            } catch {
                self.trySearchAPIRecursive(index: index + 1, keywords: keywords)
            }
        }.resume()
    }


//    private func extractKeywords(from text: String) -> [String] {
//        let regex = try? NSRegularExpression(pattern: #"[\w()가-힣]+"#, options: [])
//        let nsText = text as NSString
//        let results = regex?.matches(in: text, range: NSRange(location: 0, length: nsText.length)) ?? []
//        return results.map { nsText.substring(with: $0.range) }.filter { $0.count >= 2 }
//    }

    private func extractKeywords(from text: String) -> (names: [String], ingredients: [String]) {
        let cleaned = text.replacingOccurrences(of: "[^가-힣a-zA-Z0-9\\s]", with: " ", options: .regularExpression)
        let regex = try? NSRegularExpression(pattern: #"[\w()가-힣]+"#, options: [])
        let nsText = cleaned as NSString
        let results = regex?.matches(in: cleaned, range: NSRange(location: 0, length: nsText.length)) ?? []

        let words = results.map { nsText.substring(with: $0.range) }.filter { $0.count >= 2 }

        let drugNames = words.filter { $0.contains("정") || $0.contains("캡슐") || $0.contains("크림") || $0.contains("액") || $0.contains("지르텍") ||
            $0.range(of: #"^\d+정$"#, options: .regularExpression) == nil &&
            $0.range(of: #"^\d+캡슐$"#, options: .regularExpression) == nil
        }
        
        let ingredients = words.filter { $0.contains("염산염") || $0.contains("세티리진") || $0.contains("아세트아미노펜") }

        return (drugNames, ingredients)
    }

    
//    private func updateMedicineInfo(_ info: MedicineInfo) {
//        medicineNameLabel.text = info.name
//        ingredientLabel.text = info.ingredient
//        dosageLabel.text = info.dosage
//        effectsLabel.text = info.effects
//        precautionsLabel.text = info.precautions
//    }
    
    private func updateMedicineInfo(_ info: MedicineInfo) {
        DispatchQueue.main.async {
            self.hideLoadingAlert()
            self.medicineNameLabel.text = info.name
            self.ingredientLabel.text = info.ingredient
            self.dosageLabel.text = info.dosage
            self.effectsLabel.text = info.effects
            self.precautionsLabel.text = info.precautions
        }
    }

    private func showNoResultsFound() {
        DispatchQueue.main.async {
            self.hideLoadingAlert()
            self.medicineNameLabel.text = "검색 결과 없음"
            self.ingredientLabel.text = "인식된 텍스트로 약물 정보를 찾을 수 없습니다"
            self.dosageLabel.text = "--"
            self.effectsLabel.text = "--"
            self.precautionsLabel.text = "--"
        }
    }
    
    @IBAction func saveToHistoryTapped(_ sender: UIButton) {
        guard let image = selectedImage else { return }

        let historyItem = HistoryItem(
            image: image,
            recognizedText: recognizedText ?? "",
            medicineInfo: medicineInfo,
            date: Date()
        )
        HistoryManager.shared.saveToHistory(historyItem)

        if let info = medicineInfo {
            let db = Firestore.firestore()
            let ref = db.collection("medications")
            ref.whereField("name", isEqualTo: info.name)
                .getDocuments { snapshot, error in
                    if let snapshot = snapshot, snapshot.isEmpty {
                        ref.addDocument(data: [
                            "name": info.name,
                            "ingredient": info.ingredient,
                            "dosage": info.dosage,
                            "effects": info.effects,
                            "precautions": info.precautions
                        ]) { err in
                            if let err = err {
                                print("Firestore 저장 실패: \(err.localizedDescription)")
                            }
                        }
                    }
                }
        }

        showAlert(title: "저장 완료", message: "검색 기록에 저장되었습니다.") {
            self.navigationController?.popViewController(animated: true)
        }
    }

    private var loadingAlert: UIAlertController?

    private func showLoadingAlert() {
        loadingAlert = UIAlertController(title: nil, message: "텍스트를 인식 중입니다...\n\n", preferredStyle: .alert)
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        loadingAlert?.view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: loadingAlert!.view.centerXAnchor),
            indicator.bottomAnchor.constraint(equalTo: loadingAlert!.view.bottomAnchor, constant: -20)
        ])
        if let alert = loadingAlert {
            present(alert, animated: true)
        }
    }

    private func hideLoadingAlert() {
        loadingAlert?.dismiss(animated: true)
        loadingAlert = nil
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }
    
    @objc func retrySearchTapped(_ sender: UIButton) {
        guard let text = recognizedTextView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "오류", message: "텍스트를 입력해 주세요.")
            return
        }
        recognizedText = text
//        let keywords = extractKeywords(from: text)
//        searchMedicineInfo(with: keywords)
        searchMedicineInfo(from: text)
    }
}

extension Array {
    func combinations(ofCount k: Int) -> [[Element]] {
        guard k > 0 else { return [[]] }
        guard let first = first else { return [] }
        let rest = Array(self.dropFirst())
        let withFirst = rest.combinations(ofCount: k - 1).map { [first] + $0 }
        let withoutFirst = rest.combinations(ofCount: k)
        return withFirst + withoutFirst
    }
}
