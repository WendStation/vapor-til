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

import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  // Basic "Hello, world!" example
  router.get("hello") { req in
    return "Hello, world!"
  }

  router.post("api", "acronyms") { req -> Future<Acronym> in
    return try req.content.decode(Acronym.self).flatMap(to: Acronym.self) { acronym in
      return acronym.save(on: req)
    }
  }

  router.get("api", "acronyms") { req -> Future<[Acronym]> in
    return Acronym.query(on: req).all()
  }

  router.get("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
    return try req.parameters.next(Acronym.self)
  }

  router.put("api", "acronyms", Acronym.parameter) { req -> Future<Acronym> in
    return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self),
                       req.content.decode(Acronym.self)) { acronym, updatedAcronym in
      acronym.short = updatedAcronym.short
      acronym.long = updatedAcronym.long
      return acronym.save(on: req)
    }
  }

  router.delete("api", "acronyms", Acronym.parameter) { req -> Future<HTTPStatus> in
    return try req.parameters.next(Acronym.self).delete(on: req).transform(to: .noContent)
  }

  router.get("api", "acronyms", "search") { req -> Future<[Acronym]> in
    guard let searchTerm = req.query[String.self, at: "term"] else {
      throw Abort(.badRequest)
    }
    return Acronym.query(on: req).group(.or) { or in
      or.filter(\.short == searchTerm)
      or.filter(\.long == searchTerm)
      }.all()
  }

  router.get("api", "acronyms", "first") { req -> Future<Acronym> in
    return Acronym.query(on: req).first().unwrap(or: Abort(.notFound))
  }

  router.get("api", "acronyms", "sorted") { req -> Future<[Acronym]> in
    return Acronym.query(on: req).sort(\.short, .ascending).all()
  }
}
