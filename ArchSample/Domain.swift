//
//  Domain.swift
//  ArchSample
//
//  Created by Paul Dmitryev on 26.04.2018.
//  Copyright © 2018 MyOwnTeam. All rights reserved.
//

import Foundation

struct Domain: Decodable {
    enum CodingKeys: String, CodingKey
    {
        case name = "domain"
        case updated = "update_date"
    }

    let name: String
    let updated: String
}

struct Domains: Decodable {
    enum CodingKeys: String, CodingKey
    {
        case domains = "domains"
    }

    let domains: [Domain]
}
