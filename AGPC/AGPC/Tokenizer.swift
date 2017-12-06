//
//  File.swift
//  AGPC
//
//  Created by Andrey Gurev on 06.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  
import Foundation

public var errorMessages = [String]()

class Tokenizer {
    private var _currentToken: Token?
    private var text: String
    
    init(text: String) {
        self.text = text
        self.text.append(" \0")
        initTable()
    }
    
    private enum State: String {
        case BEGIN, INTEGER, EXP_NUMBER, DOUBLE_NUMBER, DOUBLE_NUMBER_DOT,
        WORD, SLASH, SPECIAL, BINARY_INT, HEX_INT, OCTAL_INT,
        SPECIAL_MAX, SPECIAL_DERELICT, DOUBLE_DOT, DOT, STRING,
        COMMENT, COMMENT_LONG, SHIFT, END, ENDOFFILE
        
        static var count: Int { return State.END.hashValue + 1}
    }
    private var currentState: State = .BEGIN
    private var newState: State = .BEGIN
    private var stateTable = Array(repeating: Array<State>(repeating: .END, count: 128), count: State.count)

    func nextToken() throws {
        self._currentToken = try self.analyze()
    }
    
    func currentToken() -> Token {
        if(self._currentToken == nil) {
            try! self.nextToken()
        }
        return self._currentToken!
    }
    
    // MARK: Init state table
    
    private func initTable() {
        stateTable[State.BEGIN.hashValue][Character("$").asciiValue] = .HEX_INT
        stateTable[State.BEGIN.hashValue][Character("&").asciiValue] = .OCTAL_INT
        stateTable[State.BEGIN.hashValue][Character("%").asciiValue] = .BINARY_INT
        stateTable[State.BINARY_INT.hashValue][Character("0").asciiValue] = .BINARY_INT
        stateTable[State.BINARY_INT.hashValue][Character("1").asciiValue] = .BINARY_INT
        
        for i in Character("a").asciiValue...Character("z").asciiValue {
            if(i <= Character("f").asciiValue) {
                stateTable[State.HEX_INT.hashValue][i] = .HEX_INT
            }
            stateTable[State.BEGIN.hashValue][i] = .WORD
            stateTable[State.WORD.hashValue][i] = .WORD
        }
        
        for i in Character("A").asciiValue...Character("Z").asciiValue {
            if(i <= Character("F").asciiValue) {
                stateTable[State.HEX_INT.hashValue][i] = .HEX_INT
            }
            stateTable[State.BEGIN.hashValue][i] = .WORD
            stateTable[State.WORD.hashValue][i] = .WORD
        }
        
        stateTable[State.WORD.hashValue][Character("_").asciiValue] = .WORD
        stateTable[State.BEGIN.hashValue][Character("_").asciiValue] = .WORD
        
        for i in Character("0").asciiValue...Character("9").asciiValue {
            if(i < Character("8").asciiValue) {
                stateTable[State.OCTAL_INT.hashValue][i] = .OCTAL_INT
            }
            stateTable[State.BEGIN.hashValue][i] = .INTEGER
            stateTable[State.INTEGER.hashValue][i] = .INTEGER
            stateTable[State.WORD.hashValue][i] = .WORD
            
            stateTable[State.DOUBLE_NUMBER.hashValue][i] = .DOUBLE_NUMBER
            stateTable[State.DOUBLE_NUMBER_DOT.hashValue][i] = .DOUBLE_NUMBER
            stateTable[State.EXP_NUMBER.hashValue][i] = .EXP_NUMBER
            stateTable[State.HEX_INT.hashValue][i] = .HEX_INT
        }
    
        stateTable[State.INTEGER.hashValue][Character(".").asciiValue] = .DOUBLE_NUMBER_DOT
        stateTable[State.DOUBLE_NUMBER.hashValue][Character("E").asciiValue] = .EXP_NUMBER
        stateTable[State.DOUBLE_NUMBER.hashValue][Character("e").asciiValue] = .EXP_NUMBER
        stateTable[State.DOUBLE_NUMBER_DOT.hashValue][Character(".").asciiValue] = .END
        
        stateTable[State.BEGIN.hashValue][Character(" ").asciiValue] = .SHIFT
        stateTable[State.BEGIN.hashValue][Character("\n").asciiValue] = .SHIFT
        stateTable[State.BEGIN.hashValue][Character("\t").asciiValue] = .SHIFT
        stateTable[State.SHIFT.hashValue][Character(" ").asciiValue] = .SHIFT
        stateTable[State.SHIFT.hashValue][Character("\n").asciiValue] = .SHIFT
        stateTable[State.SHIFT.hashValue][Character("\t").asciiValue] = .SHIFT
        
        stateTable[State.BEGIN.hashValue][Character("+").asciiValue] = .SPECIAL
        stateTable[State.BEGIN.hashValue][Character("-").asciiValue] = .SPECIAL
        stateTable[State.BEGIN.hashValue][Character("*").asciiValue] = .SPECIAL
        stateTable[State.BEGIN.hashValue][Character(">").asciiValue] = .SPECIAL
        stateTable[State.BEGIN.hashValue][Character(":").asciiValue] = .SPECIAL
        stateTable[State.BEGIN.hashValue][Character("<").asciiValue] = .SPECIAL_DERELICT
        stateTable[State.BEGIN.hashValue][Character("@").asciiValue] = .SPECIAL_MAX
        stateTable[State.BEGIN.hashValue][Character("[").asciiValue] = .SPECIAL_MAX
        stateTable[State.BEGIN.hashValue][Character("]").asciiValue] = .SPECIAL_MAX
        stateTable[State.BEGIN.hashValue][Character(";").asciiValue] = .SPECIAL_MAX
        stateTable[State.BEGIN.hashValue][Character(",").asciiValue] = .SPECIAL_MAX
        stateTable[State.BEGIN.hashValue][Character("(").asciiValue] = .SPECIAL_MAX
        stateTable[State.BEGIN.hashValue][Character(")").asciiValue] = .SPECIAL_MAX
        stateTable[State.BEGIN.hashValue][Character("=").asciiValue] = .SPECIAL_MAX
        stateTable[State.BEGIN.hashValue][Character("^").asciiValue] = .SPECIAL_MAX
        
        stateTable[State.SPECIAL.hashValue][Character("=").asciiValue] = .SPECIAL_MAX
        stateTable[State.SPECIAL_DERELICT.hashValue][Character(">").asciiValue] = .SPECIAL_MAX
        stateTable[State.SPECIAL_DERELICT.hashValue][Character("=").asciiValue] = .SPECIAL_MAX
        
        stateTable[State.BEGIN.hashValue][Character("/").asciiValue] = .SLASH
        stateTable[State.SLASH.hashValue][Character("/").asciiValue] = .COMMENT
        stateTable[State.SLASH.hashValue][Character("=").asciiValue] = .SPECIAL_MAX
        
        stateTable[State.BEGIN.hashValue][Character("{").asciiValue] = .COMMENT_LONG
        stateTable[State.BEGIN.hashValue][Character("'").asciiValue] = .STRING
        
        stateTable[State.BEGIN.hashValue][Character("\0").asciiValue] = .ENDOFFILE
        
        for i in 0..<128 {
            stateTable[State.STRING.hashValue][i] = .STRING
            stateTable[State.COMMENT.hashValue][i] = .COMMENT
            stateTable[State.COMMENT_LONG.hashValue][i] = .COMMENT_LONG
        }
        
        stateTable[State.STRING.hashValue][Character("'").asciiValue] = .END
        stateTable[State.COMMENT.hashValue][Character("\n").asciiValue] = .END
        stateTable[State.COMMENT_LONG.hashValue][Character("}").asciiValue] = .END
        
        stateTable[State.BEGIN.hashValue][Character(".").asciiValue] = .DOT
        stateTable[State.DOT.hashValue][Character(".").asciiValue] = .DOUBLE_DOT

    }

    private var i = 0
    private var symbolPosition = (row: 1, col: 2)
    private var currentCol = 1
    
    private func analyze() throws -> Token {
        var lexemText = ""
        while(true) {
            let symbol = Character(text[i])
            currentState = newState
            newState = stateTable[currentState.hashValue][symbol.asciiValue]
            switch(newState) {
            case .END:
                var result:Token?
                switch(currentState) {
                case .WORD:
                    let lexem = getKeyWordType(lexemText.lowercased())
                    result =  (lexem == nil) ? Token(lexemText, .ID, symbolPosition) : Token(lexemText, lexem!, symbolPosition)
                case .SHIFT:
                    newState = .BEGIN
                case .DOUBLE_NUMBER_DOT:
                    i-=1
                    currentCol-=1
                    lexemText = lexemText[0..<lexemText.count - 1]
                    result = Token(lexemText, .INT, symbolPosition)
                case .DOT:
                    result = Token(lexemText, .DOT, symbolPosition)
                case .DOUBLE_DOT:
                    result = Token(lexemText, .D_DOT, symbolPosition)
                case .INTEGER:
                    result = Token(lexemText, .INT, symbolPosition)
                case .DOUBLE_NUMBER:
                    result = Token(lexemText, .DOUBLE, symbolPosition)
                case .EXP_NUMBER:
                    result = Token(lexemText, .DOUBLE, symbolPosition, String(Double(lexemText)!))
                case .HEX_INT:
                    result = Token(lexemText, .INT, symbolPosition, String(Int(strtoul(lexemText.replacingOccurrences(of: "$", with: ""), nil, 16))))
                case .BINARY_INT:
                    result = Token(lexemText, .INT, symbolPosition, String(Int(strtoul(lexemText.replacingOccurrences(of: "%", with: ""), nil, 2))))
                case .OCTAL_INT:
                    result = Token(lexemText, .INT, symbolPosition, String(Int(strtoul(lexemText.replacingOccurrences(of: "&", with: ""), nil, 8))))
                case .SPECIAL_MAX, .SPECIAL, .SLASH, .SPECIAL_DERELICT:
                    result = Token(lexemText, getType(lexemText), symbolPosition)
                case .STRING:
                    lexemText.append(symbol)
                    i+=1
                    result = Token(lexemText, .STRING, symbolPosition, lexemText.replacingOccurrences(of: "'", with: ""))
                case .COMMENT_LONG:
                    lexemText.append(symbol)
                    i+=1
                    result = Token(lexemText, .LONG_COMMENT, symbolPosition)
                case .COMMENT:
                    result = Token(lexemText, .COMMENT, symbolPosition)
                default:
                    throw ParseErrors.unexpectedSymbol(symbolPosition, String(symbol))
                }
                lexemText.removeAll()
                newState = .BEGIN
                return result!
            case .SHIFT:
                if(symbol == "\n"){
                    symbolPosition.row+=1
                    currentCol = 1
                }
                newState = .BEGIN
            case .ENDOFFILE:
                return Token("EndOfFile", .ENDOFFILE, symbolPosition)
            default:
                if (lexemText.isEmpty){
                    symbolPosition = (symbolPosition.row, currentCol)
                }
                lexemText.append(symbol)
            }
            i+=1
            currentCol+=1
        }
    }
    
    func test() throws -> String {
        var text: String = lexemTable(self.currentToken());
        while(self.currentToken().type != .ENDOFFILE) {
            try nextToken()
            text.append(lexemTable(self.currentToken()))
        }
        initialDraw = true
        return text
    }
}
