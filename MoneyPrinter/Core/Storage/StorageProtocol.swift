//
//  StorageProtocol.swift
//  MoneyPrinter
//
//  Created by yangjs on 10/12/26.
//

import Foundation

protocol StorageProtocol {
    func save(_ data: Data, service: String, account: String)
    func read(service: String, account: String) -> Data?
    func delete(service: String, account: String)
}
