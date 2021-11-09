//
//  DBHelper.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/09.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import Foundation
import SQLite3

class DBHelper {
    static let shared = DBHelper()
    
    var db: OpaquePointer?
    var path = "filemusic.sqlite"
    
    init() {
        self.db = createDB()
    }
    
    func createDB() -> OpaquePointer? {
        var db: OpaquePointer? = nil
        do {
            let filePath = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(path)
            if sqlite3_open(filePath.path, &db) == SQLITE_OK { return db }
        } catch { print("Error in createDB: \(error.localizedDescription)") }
        print("error in createDB - sqlite3_open")
        return nil
    }
    
    func createTable() {
        // AUTOINCREAMENMT 를 사용하기 위해서는 INTEGER 를 사용해야 한다.
        let query = "CREATE TABLE IF NOT EXISTS playTable (id INTEGER PRIMARY KEY AUTOINCREMENT, uuid TEXT, nick TEXT, playTime TEXT, url TEXT, filename TEXT)"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("create table successfully")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("create talbe step fail: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("create table sqlite3_prepare fail: \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }
    
    func dropTable() {
        let query = "DROP TABLE playTable"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("delete table successfully \(String(describing: db))")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("delete table step fail: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("delete table prepare fail: \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }
    
    func insertPlayData(uuid: String, nick: String, playTime: String, url: String, filename: String) {
        let query = "INSERT INTO playTable(id, uuid, nick, playTime, url, filename) VALUES (?, ?, ?, ?, ?, ?)"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
            // insert 는 read 와 다르게 컬럼 순서 시작을 1부터 한다.
            sqlite3_bind_text(statement, 2, NSString(string: uuid).utf8String, -1, nil)
            sqlite3_bind_text(statement, 3, NSString(string: nick).utf8String, -1, nil)
            sqlite3_bind_text(statement, 4, NSString(string: playTime).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, NSString(string: url).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, NSString(string: filename).utf8String, -1, nil)
            if sqlite3_step(statement) == SQLITE_DONE {
                print("insert data successfully")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("insert data sqlite3_step fail: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("insert data prepare fail: \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }
    
    func getPlayHistory() -> [PLAY_HISTORY] {
        var result = [PLAY_HISTORY]()
        let query = "SELECT * FROM playTable ORDER BY playTime DESC LIMIT 20;"
        var statement: OpaquePointer? = nil
        if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                //let id = sqlite3_column_int(statement, 0)
                let uuid = String(cString: sqlite3_column_text(statement, 1))
                let nick = String(cString: sqlite3_column_text(statement, 2))
                let playTime = String(cString: sqlite3_column_text(statement, 3))
                let url = String(cString: sqlite3_column_text(statement, 4))
                let filename = String(cString: sqlite3_column_text(statement, 5))
                let play_item = PLAY_HISTORY(uuid: uuid, nick: nick, playTime: playTime, url: url, filename: filename)
                result.append(play_item)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("read data prepare fail: \(errorMessage)")
        }
        sqlite3_finalize(statement)
        return result
    }
    
}
