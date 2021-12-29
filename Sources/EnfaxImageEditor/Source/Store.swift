import RxSwift
import RxRelay
import RxCocoa

open class Store<State> {
    public typealias Mutation = (inout State) -> Void
    public typealias Action = Observable<Mutation>
    
    private let stateRelay: BehaviorRelay<State>
    public var stateDriver: Driver<State> {
        return self.stateRelay.asDriver()
    }
    public var state: State {
        return self.dispatchQueue.sync {
            return self.stateRelay.value
        }
    }
    
    private let dispatchQueue: DispatchQueue = .init(label: "com.ppurio.enFax.MVI.Store", qos: .userInitiated)
    
    public init(initialState: State) {
        self.stateRelay = .init(value: initialState)
    }
    
    public func commit(_ mutation: @escaping Mutation) {
        self.dispatchQueue.async {
            var state = self.stateRelay.value
            mutation(&state)
            self.stateRelay.accept(state)
        }
    }
    
    public func dispatch(_ action: Action) -> Completable {
        return action
            .do(onNext: { [weak self] (mutation) in
                self?.commit(mutation)
            })
            .ignoreElements()
            .asCompletable()
    }
}
