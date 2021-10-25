//
//  Helpers.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 25/10/21.
//

@testable import marvel_heroes

func anyMarvelCharacterList() -> [MarvelCharacter] {
    return [MarvelCharacter(id: 0, name: "", description: "", modified: "", thumbnail: Thumbnail(path: "", fileExtension: ""))]
}
