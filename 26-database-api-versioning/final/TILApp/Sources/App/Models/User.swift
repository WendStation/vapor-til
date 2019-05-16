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
import Authentication

final class User: Codable {
  var id: UUID?
  var name: String
  var username: String
  var password: String
  var twitterURL: String?

  init(name: String, username: String, password: String, twitterURL: String? = nil) {
    self.name = name
    self.username = username
    self.password = password
    self.twitterURL = twitterURL
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

  final class PublicV2: Codable {
    var id: UUID?
    var name: String
    var username: String
    var twitterURL: String?

    init(id: UUID?, name: String, username: String, twitterURL: String? = nil) {
      self.id = id
      self.name = name
      self.username = username
      self.twitterURL = twitterURL
    }
  }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}

extension User: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      builder.field(for: \.id, isIdentifier: true)
      builder.field(for: \.name)
      builder.field(for: \.username)
      builder.field(for: \.password)
      builder.unique(on: \.username)
    }
  }
}

extension User: Parameter {}
extension User.Public: Content {}
extension User.PublicV2: Content {}

extension User {
  var acronyms: Children<User, Acronym> {
    return children(\.userID)
  }
}

extension User {
  func convertToPublic() -> User.Public {
    return User.Public(id: id, name: name, username: username)
  }

  func convertToPublicV2() -> User.PublicV2 {
    return User.PublicV2(id: id, name: name, username: username, twitterURL: twitterURL)
  }
}

extension Future where T: User {
  func convertToPublic() -> Future<User.Public> {
    return self.map(to: User.Public.self) { user in
      return user.convertToPublic()
    }
  }

  func convertToPublicV2() -> Future<User.PublicV2> {
    return self.map(to: User.PublicV2.self) { user in
      return user.convertToPublicV2()
    }
  }
}

extension User: BasicAuthenticatable {
  static let usernameKey: UsernameKey = \User.username
  static let passwordKey: PasswordKey = \User.password
}

extension User: TokenAuthenticatable {
  typealias TokenType = Token
}

struct AdminUser: Migration {

  typealias Database = PostgreSQLDatabase

  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    let password = try? BCrypt.hash("password")
    guard let hashedPassword = password else {
      fatalError("Failed to create admin user")
    }
    let user = User(name: "Admin", username: "admin", password: hashedPassword)
    return user.save(on: connection).transform(to: ())
  }

  static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
    return Future.map(on: connection) {}
  }
}

extension User: PasswordAuthenticatable {}
extension User: SessionAuthenticatable {}
