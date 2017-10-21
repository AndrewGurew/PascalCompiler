//
//  TokenType.swift
//  AGPC
//
//  Created by Andrey Gurev on 16.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation
enum TokenEnum:String {
    
    //Special symbols
    case PLUS, MINUS, DIV, MOD, MULT, EQUAL,
    COMMA, COLON, SEMICOLON, LESS, MORE, DOT, L_BRACKET, R_BRACKET,
    LSQR_BRACKET, RSQR_BRACKET, POINTER, DOG
    
    //Double special symbols
    case PLUS_ASSIGN, MINUS_ASSIGN, DIV_ASSIGN, MULT_ASSIGN, NOT_EQUAL,
    LESS_EQUAL, MORE_EQUAL, ASSIGN, D_DOT
    
    //Types
    case INT = "Integer", DOUBLE = "Double", STRING = "String"
    
    //Keywords
    case PROCEDURE, RECORD, IF, THEN, ELSE, FOR, TO, REPEAT, UNTIL,
    BREAK, CONTINUE, CASE, VAR, TYPE, ARRAY, OF, CONST, TRUE, PROGRAM,
    FALSE, AND, NOT, OR, DOWNTO, EOF, WHILE, BEGIN, END,
    FORWARD, DO, FUNCTION, UNTILL
    
    //Other
    case ID = "Id", COMMENT = "Comments", LONG_COMMENT = "Long comments",
    ENDOFFILE = "End of file"
}

struct TokenType {
    var enumType: TokenEnum
    var strType: String
    init(_ type: TokenEnum,_ name: String) {
        self.enumType = type
        self.strType = name
    }
    
    init(_ type: TokenEnum) {
        self.enumType = type
        self.strType = self.enumType.rawValue
    }
}

private var symbolsInfo:[String:TokenType] = [
    //MARK:Special symbols
    "+": TokenType(.PLUS, "Plus"),
    "-": TokenType(.MINUS, "Minus"),
    "*": TokenType(.MULT, "Mult"),
    "/": TokenType(.DIV, "Div"),
    "^": TokenType(.POINTER, "Pointer"),
    "@": TokenType(.DOG, "Dog"),
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

private var keyWordInfo:[String: TokenEnum] = [
    "begin": .BEGIN, "end": .END, "program": .PROGRAM, "var": .VAR,
    "and": .AND, "array": .ARRAY, "break": .BREAK, "case": .CASE,
    "const": .CONST, "div": .DIV, "while": .WHILE, "for": .FOR,
    "if": .IF, "else": .ELSE, "true": .TRUE, "function": .FUNCTION,
    "procedure": .PROCEDURE, "mod": .MOD, "not": .NOT,
    "or": .OR, "until": .UNTILL, "type": .TYPE
]

func getType(_ key: String) -> TokenType {
    return symbolsInfo[key]!
}

func getKeyWordType(_ text: String) -> TokenEnum? {
    return keyWordInfo[text]
}
