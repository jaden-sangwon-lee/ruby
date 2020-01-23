//
//  ViewController.swift
//  RubyApp
//
//  Created by Jaden on 2020/01/23.
//  Copyright © 2020 sangwon.lee. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {

    // ルビー変換データ
    var rubyData = [String]()
    
    // テーブルビュー設定
    @IBOutlet weak var tableView: UITableView!{
        didSet{
            tableView.delegate = self
            tableView.dataSource = self
            tableView.separatorStyle = .none
        }
    }
    
    // 日本語入力ビュー
    @IBOutlet weak var textview: UIView!
    
    // 日本語入力テキストビュー設定
    @IBOutlet weak var inputTextView: UITextView! {
        didSet {
            inputTextView.delegate = self
        }
    }
    
    // 日本語入力テキストビュー高さ
    @IBOutlet weak var inputTextViewHeight: NSLayoutConstraint!
    
    // 日本語入力ビューマージン
    @IBOutlet weak var inputViewBottmmargin: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // テーブルビューセル登録
        tableView.register(UINib(nibName: "JapaneseCell", bundle: nil), forCellReuseIdentifier: "japaneseCell")
        tableView.register(UINib(nibName: "HiraganaCell", bundle: nil), forCellReuseIdentifier: "hiraganaCell")
        
        // キーボードオブザーバー (表示用)
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        // キーボードオブザーバー (非表示用)
        NotificationCenter.default.addObserver(self, selector: #selector(keybordWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // キーボード表示時、日本語入力ビューをキーボード上に移動
    @objc func keybordWillShow(noti:Notification) {
        let notiInfo = noti.userInfo!
        let keyboardFrame = notiInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        let keyboardAni = notiInfo[UIResponder.keyboardAnimationDurationUserInfoKey ] as! TimeInterval
        
        let height = keyboardFrame.size.height - self.view.safeAreaInsets.bottom
        
        UIView.animate(withDuration: keyboardAni) {
            self.inputViewBottmmargin.constant = height
            self.view.layoutIfNeeded()
        }
    }
    
    // キーボード非表示、日本語入力ビューを画面下部に移動
    @objc func keybordWillHide(noti:Notification) {
        let notiInfo = noti.userInfo!
        let keyboardAni = notiInfo[UIResponder.keyboardAnimationDurationUserInfoKey ] as! TimeInterval
        
        UIView.animate(withDuration: keyboardAni) {
            self.inputViewBottmmargin.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rubyData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row%2 == 0 {
            let japaneseCell = tableView.dequeueReusableCell(withIdentifier: "japaneseCell", for: indexPath) as! JapaneseCell
            japaneseCell.textview.text = rubyData[indexPath.row]
            japaneseCell.selectionStyle = .none;
            return japaneseCell
        } else {
            let hiraganaCell = tableView.dequeueReusableCell(withIdentifier: "hiraganaCell", for: indexPath) as! HiraganaCell
            hiraganaCell.textview.text = rubyData[indexPath.row]
            hiraganaCell.selectionStyle = .none;
            return hiraganaCell
        }
    }
    
    // 日本語入力時、テキストビューの高さ自動に調節
    func textViewDidChange(_ textView: UITextView) {
        if textView.contentSize.height <= 50 {
            inputTextViewHeight.constant = 50;
        } else if textView.contentSize.height >= 100 {
            inputTextViewHeight.constant = 100
        } else {
            inputTextViewHeight.constant = textView.contentSize.height
        }
    }
    
    // ひらがな化APIを呼ぶ
    func callHiraganaApi(sentence: String) {
        var postParameter = Dictionary<String,Any>()
        postParameter["app_id"] = "6ee09d78fbe4f0dcaf330fe18c559698933642a52e13855d77166c452a36f3ad"
        postParameter["sentence"] = sentence
        postParameter["output_type"] = "hiragana"
        
        var request = URLRequest(url: URL(string: hiraganaApiUrl)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: postParameter, options: .prettyPrinted)
        } catch {
            print(error.localizedDescription)
        }

        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let data = data {
                do {
                    let json = try JSONDecoder().decode(HiraganaJson.self, from: data)
                    DispatchQueue.main.async {
                        self.setHiragana(hiragana:json.converted);
                    }
                    print("data ==> \(json)")
                } catch {
                    DispatchQueue.main.async {
                        self.setHiragana(hiragana:"ひらがな変換に失敗しました。");
                    }
                    print("Error ==> \(error)")
                }
            }
        })
        task.resume()
    }
    
    // 変換後のひらがなを画面に表示
    func setHiragana(hiragana: String){
        rubyData.append(hiragana)
        
        let lastIndexPath = IndexPath(row: rubyData.count - 1, section:0)
        tableView.insertRows(at: [lastIndexPath], with: UITableView.RowAnimation.automatic)
        tableView.scrollToRow(at: lastIndexPath, at: UITableView.ScrollPosition.bottom, animated: true)
    }

    // 変換ボタン押下し処理
    @IBAction func sendString(_ sender: Any) {
        rubyData.append(inputTextView.text)
        
        callHiraganaApi(sentence: inputTextView.text)
        
        inputTextView.text = ""
        inputTextViewHeight.constant = 50;
        
        let lastIndexPath = IndexPath(row: rubyData.count - 1, section:0)
        tableView.insertRows(at: [lastIndexPath], with: UITableView.RowAnimation.automatic)
        tableView.scrollToRow(at: lastIndexPath, at: UITableView.ScrollPosition.bottom, animated: true)
    }
}

