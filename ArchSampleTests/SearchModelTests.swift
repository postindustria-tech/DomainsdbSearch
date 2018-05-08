//
//  ArchSampleTests.swift
//  ArchSampleTests
//
//  Created by Paul Dmitryev on 26.04.2018.
//  Copyright © 2018 MyOwnTeam. All rights reserved.
//

import Alamofire
import RxBlocking
import RxSwift
import XCTest

@testable import ArchSample

class MockNetworkManager: NetworkManager {
    let isLoading: Observable<Bool> = Observable.never()

    private let mockData: Data

    init(stubName: String) {
        let url = Bundle(for: MockNetworkManager.self).url(forResource: stubName, withExtension: "json")!
        self.mockData = try! Data(contentsOf: url)
    }

    func makeRequest<Result: Decodable>(method: HTTPMethod, url: URLConvertible, params: Parameters) -> Observable<Result?> {
        let parsed = try! JSONDecoder().decode(Result.self, from: self.mockData)
        return Observable.just(parsed)
    }
}

class SearchModelTests: XCTestCase {
    private var stubModel: DomainerSearchViewModel {
        let manager = MockNetworkManager(stubName: "SearchStub")
        let params = Observable.just(SearchParameters(request: "Med"))
        return DomainerSearchViewModel(networkManager: manager, parameters: params)
    }

    func testParsing() {
        let result = try! stubModel.results.toBlocking().single()

        XCTAssertEqual(result.count, 50)

        let sample = result.first!

        XCTAssertEqual(sample.name, "med-med-buy.com")
        XCTAssertEqual(sample.updated, "2018-01-11T05:29:12.517Z")
    }

    func testActivity() {
        var result: [Bool] = []
        let disposeBag = DisposeBag()

        let model = stubModel
        model.isActive
            .subscribe(onNext: { state in
                result.append(state)
            })
            .disposed(by: disposeBag)

        _ = try! model.results.toBlocking().single()

        XCTAssertEqual(result, [true, false])
    }
}
