//
//  DomainSearchModel.swift
//  ArchSample
//
//  Created by Paul Dmitryev on 26.04.2018.
//  Copyright © 2018 MyOwnTeam. All rights reserved.
//

import Foundation
import RxSwift

struct SearchParameters {
    let request: String
}

protocol SearchModel {
    init(networkManager: NetworkManager, parameters: Observable<SearchParameters>)
    var results: Observable<[Domain]> { get }
    var isActive: Observable<Bool> { get }
}

struct DomainerSearchModel: SearchModel {
    private static let url = "https://api.domainsdb.info/search"
    private let manager: NetworkManager
    private let params: Observable<SearchParameters>
    private let activity = ReplaySubject<Bool>.create(bufferSize: 1)

    let results: Observable<[Domain]>
    let isActive: Observable<Bool>

    init(networkManager: NetworkManager, parameters: Observable<SearchParameters>) {
        self.manager = networkManager
        self.params = parameters

        self.results = params
            .do(onNext: { [weak activity] _ in
                activity?.onNext(true)
            })
            .flatMapLatest { [manager] params -> Observable<Domains?> in
                guard !params.request.isEmpty else {
                    return Observable.just(nil)
                }
                let qryParams = ["query": params.request]
                return manager.makeRequest(method: .get, url: DomainerSearchModel.url, params: qryParams)
            }
            .map { data in
                return data?.domains ?? []
            }
            .do(onNext: { [weak activity] _ in
                activity?.onNext(false)
            })
            .observeOn(MainScheduler.instance)
            .share(replay: 1)

        self.isActive = activity.asObservable()
            .observeOn(MainScheduler.instance)
            .share(replay: 1)
    }

}
