//
//  Errors.swift
//  AGPC
//
//  Created by Andrey Gurev on 04.12.2017.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

enum ParseErrors: Error {
    case unknownSymbol((Int, Int), String)
    case unexpectedSymbol((Int, Int), String)
    case unknownIdentifier((Int, Int), String)
    case unexpectedSymbolBefore((Int, Int), String, String)
    case duplicateDeclaration((Int, Int), String)
    case other(String)
    case unknownError()
    case unexpectedType((Int, Int), String)
}

func unknownSymbolMessage(_ pos: (Int, Int),_ text: String) -> String  {
    return "\(pos) - unknown symbol \(text)"
}

func unknownIdentifierMessage(_ pos: (Int, Int),_ text: String) -> String  {
    return "\(pos) - identifier \(text) is not declared"
}

func unexpectedSymbolBeforeMessage(_ pos: (Int, Int),_ requreText:String,_ text: String) -> String {
    return "\(pos) - expected \(requreText) before \(text)"
}

func unexpectedSymbolMessage(_ pos: (Int, Int),_ text:String) -> String {
    return "\(pos) - unexpected symbol \(text)"
}

func duplicateDeclarationMessage(_ pos: (Int, Int),_ text: String) -> String {
    return "\(pos) - duplicate declaration of \(text)"
}

func unexpectedTypeMessage(_ pos: (Int, Int),_ text: String) -> String {
    return "\(pos) - unexpected type \(text)"
}

func otherMessage(_ text: String) -> String {
    return text
}

func unknownErrorMessage() -> String {
    return "Unknown error"
}


