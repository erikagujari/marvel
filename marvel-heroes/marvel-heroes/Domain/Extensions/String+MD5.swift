//
//  String+MD5.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 25/10/21.
//
import CryptoKit

extension String {
    func toMD5String() -> String {
        guard let data = data(using: .utf8) else { return self }
        
        return Insecure.MD5.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
    }
}
