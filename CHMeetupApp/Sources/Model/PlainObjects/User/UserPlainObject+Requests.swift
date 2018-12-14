//
//  UserPlainObject+Requests.swift
//  CHMeetupApp
//
//  Created by Sam on 28/02/2017.
//  Copyright © 2017 CocoaHeads Community. All rights reserved.
//

import Foundation
import RealmSwift

extension UserPlainObject: PlainObjectType {

  struct Requests {
    // Users list
    static var list: Request<[UserPlainObject]> {
      return Request(query: "users")
    }

    // Authorization via social network
    static func auth(token: String, secret: String, socialId: String) -> Request<UserPlainObject> {
        let params = ["token": token, "secret": secret, "social": socialId]
        return Request<UserPlainObject>(query: "user/auth", method: .post, params: params)
    }

    // Get profile info
    static func profile(token: String) -> Request<UserPlainObject> {
        let params = ["token": token]
        return Request<UserPlainObject>(query: "user/profile", method: .post, params: params)
    }

    // Example of custom parser
    static var listOfIds: Request<[UserPlainObject]> {
      let parser = RequestContentParser<[UserPlainObject]> { (jsonObject: Any) -> ([UserPlainObject]?, ServerError?) in
        guard let json = jsonObject as? [JSONDictionary] else {
          return (nil, .wrongResponse)
        }
        let objects: [UserPlainObject] = json.compactMap(UserPlainObject.init(justId:))
        return (objects, nil)
      }

      return Request(query: "users", parser: parser)
    }
  }
}

extension UserPlainObject {

  init?(json: JSONDictionary) {
    guard
      let id = json["id"] as? Int,
      let name = json["name"] as? String,
      let lastname = json["lastname"] as? String,
      let status = json["regStatus"] as? String
    else { return nil }

    self.id = id
    self.name = name
    self.lastname = lastname
    self.status = status
    photoUrl = json["photo_url"] as? String
    company = json["company"] as? String
    position = json["position"] as? String
    token = json["token"] as? String
    phone = json["phone"] as? String
    email = json["email"] as? String
  }

  init?(justId json: JSONDictionary) {
    guard
      let id = json["id"] as? Int
    else { return nil }

    self.id = id
    name = ""
    lastname = ""
    status = ""
    position = nil
    company = nil
    photoUrl = nil
    token = nil
    phone = nil
    email = nil
  }
}
