//
//  TokenType.swift
//  AGPC
//
//  Created by Andrey Gurev on 16.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

struct Token {
    var position:(row: Int, col: Int)
    var type: TokenType
    var text: String
    var value: String
    init(_ text: String,_ type: TokenType,_ position:(Int, Int),_ value:String = "") {
        self.type = type
        self.text = text
        self.value = (value.isEmpty) ? self.text : value
        self.position = position
    }
}

enum TokenType: String {
    
    //Special symbols
    case PLUS = "Plus", MINUS = "Minus", DIV = "Div", MOD = "Mod",
    MULT = "Mult", EQUAL = "Equal", COMMA = "Comma", COLON = "Colon", SEMICOLON = "Semicolon",
    LESS = "Less", MORE = "More", DOT = "Dot", L_BRACKET = "Left bracket", R_BRACKET = "Right bracket",
    LSQR_BRACKET = "Left square bracket", RSQR_BRACKET = "Right square bracket",
    POINTER = "Pointer", DOG = "Dog"
    
    //Double special symbols
    case PLUS_ASSIGN = "Plus and assign", MINUS_ASSIGN = "Minus and assign",
    DIV_ASSIGN = "Div and assign", MULT_ASSIGN = "Mult and assign", NOT_EQUAL = "Not equal",
    LESS_EQUAL = "Less and equal", MORE_EQUAL = "More and equal", ASSIGN = "Assign" ,
    D_DOT = "Double dot"
    
    //Types
    case INT = "Integer", DOUBLE = "Double", STRING = "String", BOOL = "Boolean"
    
    //Keywords
    case PROCEDURE = "Procedure", RECORD = "Record", IF = "If", THEN = "Then",
    ELSE = "Else", FOR = "For", TO = "To", REPEAT = "Repeat", UNTIL = "Until",
    BREAK = "Break", CONTINUE = "Continue", CASE = "Case", VAR = "Var", TYPE = "Type",
    ARRAY = "Array", OF = "Of", CONST = "Const", TRUE = "True", PROGRAMM = "Programm",
    FALSE = "False", AND = "And", NOT = "Not", OR = "Or", DOWNTO = "Downto", EOF = "EOF",
    WHILE = "While", BEGIN = "Begin", END = "End", FORWARD = "Forward", DO = "Do",
    FUNCTION = "Function", UNKNOWN = "Unknown"
    
    //Other
    case ID = "Id", COMMENT = "Comments", LONG_COMMENT = "Long comments",
    ENDOFFILE = "End of file"
}

private var symbolsInfo:[String:TokenType] = [
    //MARK:Special symbols
    "+": .PLUS, "-": .MINUS, "*": .MULT, "/": .DIV,
    "^": .POINTER, "@": .DOG, "=": .EQUAL, ":": .COLON,
    ";": .SEMICOLON, ">": .MORE, "<": .LESS, ".": .DOT,
    ",": .COMMA, "(": .L_BRACKET, ")": .R_BRACKET,
    "[": .LSQR_BRACKET, "]": .RSQR_BRACKET,
    //MARK:Double special
    "<>": .NOT_EQUAL, "*=": .MULT_ASSIGN, "+=": .PLUS_ASSIGN,
    "/=": .DIV_ASSIGN, "-=": .MINUS_ASSIGN, ">=": .MORE_EQUAL,
    "<=": .LESS_EQUAL, "..": .D_DOT, ":=": .ASSIGN
]

private var keyWordInfo:[String: TokenType] = [
    "begin": .BEGIN, "end": .END, "program": .PROGRAMM, "var": .VAR,
    "and": .AND, "array": .ARRAY, "break": .BREAK, "case": .CASE,
    "const": .CONST, "div": .DIV, "while": .WHILE, "for": .FOR,
    "if": .IF, "else": .ELSE, "true": .TRUE, "function": .FUNCTION,
    "procedure": .PROCEDURE, "mod": .MOD, "not": .NOT, "do": .DO,
    "or": .OR, "until": .UNTIL, "type": .TYPE, "to": .TO, "of": .OF,
    "integer": .INT, "double": .DOUBLE, "then": .THEN, "repeat": .REPEAT,
    "record": .RECORD, "forward": .FORWARD, "boolean": .BOOL
]

private var types:[TokenType] = [.INT, .DOUBLE, .STRING, .BOOL]

func getType(_ key: String) -> TokenType {
    return symbolsInfo[key]!
}

func getKeyWordType(_ text: String) -> TokenType? {
    return keyWordInfo[text]
}
