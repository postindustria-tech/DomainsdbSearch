//
//  NetworkManager.swift
//  ArchSample
//
//  Created by Paul Dmitryev on 26.04.2018.
//  Copyright © 2018 MyOwnTeam. All rights reserved.
//

import Alamofire
import Foundation
import RxAlamofire
import RxSwift
import RxOptional

protocol NetworkManager {
    var isLoading: Observable<Bool> { get }
    func makeRequest<Model: Decodable>(method: HTTPMethod, url: URLConvertible, params: Parameters) -> Observable<Model?>
}

struct AfNetworkManager: NetworkManager {
    private let disposeBag = DisposeBag()
    private let activity = PublishSubject<Bool>()

    let isLoading: Observable<Bool>

    init(bindNetworkActivityIndicator: Bool = true) {
        self.isLoading = activity.asObservable()
            .share(replay: 1)

        if bindNetworkActivityIndicator {
            isLoading.asDriver(onErrorJustReturn: false)
                .drive(UIApplication.shared.rx.isNetworkActivityIndicatorVisible)
                .disposed(by: disposeBag)
        }
    }

    func makeRequest<Model: Decodable>(method: HTTPMethod, url: URLConvertible, params: Parameters) -> Observable<Model?> {
        activity.onNext(true)
        return request(method, url, parameters: params)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .flatMap { $0.rx.responseData() }
            .do(onNext: { [activity] _ in
                activity.onNext(false)
            })
            .map { _, data -> Model? in
                return try? JSONDecoder().decode(Model.self, from: data)
            }
            .catchError { [activity] error in
                print("!!! We've got an error \(error.localizedDescription)")
                activity.onNext(false)
                return Observable.just(nil)
            }
    }
}
