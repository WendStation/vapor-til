/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import Vapor
import FluentPostgreSQL

final class User: Codable {
  var id: UUID?
  var name: String
  var username: String
  var password: String

    init(name: String, username: String, password: String) {
        self.name = name
        self.username = username
        self.password = password
    }
    
    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {
    static func prepare(on connection: PostgreSQLConnection)
        -> Future<Void> {
            // 1
            return Database.create(self, on: connection) { builder in
                // 2
                try addProperties(to: builder)
                // 3
                builder.unique(on: \.username)
            }
    }
}
extension User: Parameter {}

extension User.Public: Content {}
extension User.Public: PostgreSQLUUIDModel {}

extension User {
  var acronyms: Children<User, Acronym> {
    return children(\.userID)
  }
}
extension User {
    // 1
    func convertToPublic() -> User.Public {
        // 2
        return User.Public(id: id, name: name, username: username)
    }
}
extension Future where T: User {
    // 2
    func convertToPublic() -> Future<User.Public> {
        // 3
        return self.map(to: User.Public.self) { user in
            // 4
            return user.convertToPublic()
        }
    }
}


