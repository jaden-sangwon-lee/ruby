//
//  API.swift
//  RubyApp
//
//  Created by Jaden on 2020/01/23.
//  Copyright © 2020 sangwon.lee. All rights reserved.
//

import UIKit

let hiraganaApiUrl = "https://labs.goo.ne.jp/api/hiragana"

struct HiraganaJson: Codable {
    let converted: String
    let output_type: String
    let request_id: String
}

extension Dictionary {
    var queryString: String {
        var output = ""
        for (key, value) in self {
            output = output + "\(key)=\(value)&"
        }
        
        output = String(output.dropLast())
        return output
    }
}
