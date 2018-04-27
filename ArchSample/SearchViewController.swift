//
//  ViewController.swift
//  ArchSample
//
//  Created by Paul Dmitryev on 26.04.2018.
//  Copyright © 2018 MyOwnTeam. All rights reserved.
//

import PKHUD
import RxCocoa
import RxSwift
import UIKit

class SearchViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultsTable: UITableView!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    private let disposeBag = DisposeBag()
    private lazy var parametersObservable: Observable<SearchParameters> = {
        return searchBar.rx.text
            .orEmpty
            .debounce(0.5, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .map { SearchParameters(request: $0) }
            .share(replay: 1)
    }()

    private lazy var model: SearchModel = DomainerSearchModel(networkManager: AfNetworkManager(), parameters: self.parametersObservable)

    private lazy var gotResults: Driver<Bool> = self.model.results.map { !$0.isEmpty }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        model.results
            .drive(resultsTable.rx.items) { (tableView, _, element) in
                let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell")!
                cell.textLabel?.text = element.name
                cell.detailTextLabel?.text = element.updated
                return cell
            }
            .disposed(by: disposeBag)

        model.isActive
            .drive(onNext: { state in
                if state {
                    HUD.show(.progress)
                } else {
                    HUD.hide()
                }
            })
            .disposed(by: disposeBag)

        model.isActive
            .map { !$0 }
            .drive(searchBar.rx.isUserInteractionEnabled)
            .disposed(by: disposeBag)

        gotResults
            .drive(messageView.rx.isHidden)
            .disposed(by: disposeBag)

        Observable.combineLatest(gotResults.asObservable(), parametersObservable)
            .filter { !$0.0 }
            .map { $0.1.request.isEmpty }
            .subscribe(onNext: { [messageLabel] emptyRequest in
                messageLabel?.text = emptyRequest ? "Please, search something" : "No result for this request"
            })
            .disposed(by: disposeBag)
    }
}

