//
//  Result+extensions.swift
//  Features
//
//  Created by Kamaal M Farah on 5/4/25.
//

extension Result {
    @discardableResult
    func onSuccess(_ handler: (_ success: Success) -> Void) -> Result<Success, Failure> {
        switch self {
        case .failure: break
        case let .success(success): handler(success)
        }

        return self
    }

    @discardableResult
    func onFailure(_ handler: (_ failure: Failure) -> Void) -> Result<Success, Failure> {
        switch self {
        case let .failure(failure): handler(failure)
        case .success: break
        }

        return self
    }

    func getOrNil() -> Success? {
        switch self {
        case .failure: return nil
        case let .success(success): return success
        }
    }

}
