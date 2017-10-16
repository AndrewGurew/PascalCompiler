//
//  TokenType.swift
//  AGPC
//
//  Created by Andrey Gurev on 16.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation
enum Type:String {
    
    //Special symbols
    case PLUS, MINUS, DIV, MULT, EQUAL,
    COMMA, COLON, SEMICOLON, LESS, MORE, DOT, L_BRACKET, R_BRACKET,
    LSQR_BRACKET, RSQR_BRACKET
    
    //Double special symbols
    case PLUS_ASSIGN, MINUS_ASSIGN, DIV_ASSIGN, MULT_ASSIGN, NOT_EQUAL,
    LESS_EQUAL, MORE_EQUAL, ASSIGN, D_DOT
    
    //Numbers
    case INT = "Integer", DOUBLE = "Double", EX_DOUBLE = "Exponential double",
    HEX = "Hex", OCTAL = "Octal", BINARY = "Binary"
    
    //Other
    case ID = "Id", KEYWORD = "Keyword", STRING = "String",
    COMMENT = "Comments", LONG_COMMENT = "Long comments"
}

struct TokenType {
    var enumType: Type
    var strType: String
    init(_ type: Type,_ name: String) {
        self.enumType = type
        self.strType = name
    }
    
    init(_ type: Type) {
        self.enumType = type
        self.strType = self.enumType.rawValue
    }
}

private var keyWords = ["begin", "end", "program", "var", "and", "array", "break", "case", "const", "div", "do", "while", "for", "if", "else", "false", "true", "function", "procedure", "goto", "mod", "not", "nil", "object", "or", "until", "type"]

func isKeyWord(_ text: String) -> Bool {
    return keyWords.index(of: text.lowercased()) != nil
}

private var tokenInfos:[String:TokenType] = [
    //MARK:Special symbols
    "+": TokenType(.PLUS, "Plus"),
    "-": TokenType(.MINUS, "Minus"),
    "*": TokenType(.MULT, "Mult"),
    "/": TokenType(.DIV, "Div"),
    "=": TokenType(.EQUAL, "Equal"),
    ":": TokenType(.COLON, "Colon"),
    ";": TokenType(.SEMICOLON, "SemiColon"),
    ">": TokenType(.MORE, "More"),
    "<": TokenType(.LESS, "Less"),
    ".": TokenType(.DOT, "Dot"),
    ",": TokenType(.COMMA, "Comma"),
    "(": TokenType(.L_BRACKET, "Left bracket"),
    ")": TokenType(.R_BRACKET, "Right bracket"),
    "[": TokenType(.LSQR_BRACKET, "Left square bracket"),
    "]": TokenType(.RSQR_BRACKET, "Right square bracket"),
    //MARK:Double special symbols
    "<>": TokenType(.NOT_EQUAL, "Not assign"),
    "*=": TokenType(.MULT_ASSIGN, "Mult and assign"),
    "+=": TokenType(.PLUS_ASSIGN, "Plus and assign"),
    "/=": TokenType(.DIV_ASSIGN, "Div and assign"),
    "-=": TokenType(.MINUS_ASSIGN, "Minus and assign"),
    ">=": TokenType(.MORE_EQUAL, "More or equal"),
    "<=": TokenType(.LESS_EQUAL, "Less or equal"),
    "..": TokenType(.D_DOT, "Double dot"),
    ":=": TokenType(.ASSIGN, "Assign"),
]

func getType(_ key: String) -> TokenType {
    return tokenInfos[key]!
}
