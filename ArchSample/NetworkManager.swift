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

typealias JSON = [String: Any]

protocol NetworkManager {
    func makeRequest<Result: Decodable>(method: HTTPMethod, url: URLConvertible, params: Parameters) -> Observable<Result?>
}

extension NetworkManager {
    func setNetworkIndicator(status: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = status
        }
    }
}

struct AfNetworkManager: NetworkManager {
    func makeRequest<Result: Decodable>(method: HTTPMethod, url: URLConvertible, params: Parameters) -> Observable<Result?> {
        setNetworkIndicator(status: true)
        return request(method, url, parameters: params)
            .do(onNext: { _ in
                self.setNetworkIndicator(status: false)
            })
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .flatMap { $0.rx.responseData() }
            .map { _, data -> Result? in
                return try? JSONDecoder().decode(Result.self, from: data)
            }
            .catchError { error in
                print("!!! We've got an error \(error.localizedDescription)")
                return Observable.just(nil)
            }
    }
}
