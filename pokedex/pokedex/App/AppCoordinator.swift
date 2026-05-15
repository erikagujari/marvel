//
//  AppCoordinator.swift
//  pokedex
//

import Observation

enum Route: Hashable, Sendable {
    case detail(id: Int)
}

@Observable @MainActor
final class AppCoordinator {
    var path: [Route] = []

    func showDetail(id: Int) {
        path.append(.detail(id: id))
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
