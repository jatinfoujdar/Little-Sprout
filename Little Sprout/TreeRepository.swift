//
//  TreeRepository.swift
//  Little Sprout
//
//  Created by jatin foujdar on 12/06/26.
//

import Foundation

struct TreeResponse: Codable {
    var entities: [TreeData]
    var count: Int
}

class TreeRepository {
    static let shared = TreeRepository()
    
    func fetchTrees() async throws -> [TreeData] {
        guard let bundleUrl = Bundle.main.url(forResource: "entity_data", withExtension: "json") else {
            throw NSError(
                domain: "TreeRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "entity_data.json not found in App Bundle. Please drag it into your Xcode project navigator."]
            )
        }
        
        let data = try Data(contentsOf: bundleUrl)
        let response = try JSONDecoder().decode(TreeResponse.self, from: data)
        let trees = response.entities.filter { $0.id != "weathered" }
        StorageManager.shared.cacheTrees(trees)
        return trees
    }
}
