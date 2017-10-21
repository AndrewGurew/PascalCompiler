//
//  Parser.swift
//  AGPC
//
//  Created by Andrey Gurev on 13.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

class Expression {
    enum Kind {
        case BINARY, INT, DOUBLE, ID
    }
    
    var text: String
    var kind: Kind
    var position:(col: Int, row: Int)
    
    let leftChild: Expression?
    let rightChild: Expression?
    
    init(_ position: (Int, Int),_ kind: Kind,_ text: String, _ leftChild: Expression? = nil,_ rightChild: Expression? = nil) {
        self.text = text
        self.position = position
        self.leftChild = leftChild
        self.rightChild = rightChild
        
        self.kind = kind
    }
}

class BinaryExpr: Expression {
    var special: String
    init(_ position: (Int, Int),_ special: String, leftChild: Expression?, rightChild: Expression?) {
        self.special = special
        super.init(position, .BINARY, self.special, leftChild, rightChild)
    }
}

class IDExpr: Expression {
    var name: String
    init(name: String,_ position: (Int, Int)) {
        self.name = name
        super.init(position, .ID, self.name)
    }
}

class IntegerExp: Expression {
    var value: UInt64
    init(value: UInt64,_ position: (Int, Int)) {
        self.value = value
        super.init(position, .INT, String(self.value))
    }
}

class DoubleExp: Expression {
    var value: Double
    init(value: Double,_ position: (Int, Int)) {
        self.value = value
        super.init(position, .DOUBLE, String(self.value))
    }
}

class Parser {
    private var tokenizer:Tokenizer
    private var root: Expression?
    
    init(tokenizer: Tokenizer) {
        self.tokenizer = tokenizer
        self.root = parseBoolExpr()
    }
    
    private func require(_ token: TokenType) -> Bool {
        if(token.enumType != tokenizer.currentToken().type.enumType) {
            print("Expected: \(token.strType) in \(tokenizer.currentToken().position)")
            return false
        }
        return true
    }
    
    private func parseBoolExpr() -> Expression? {
        var result = parseExpr()
        if (result == nil) {
            return nil
        }
        while(tokenizer.currentToken().type.enumType == .MORE || tokenizer.currentToken().type.enumType == .LESS ||
            tokenizer.currentToken().type.enumType == .MORE_EQUAL || tokenizer.currentToken().type.enumType == .LESS_EQUAL ||
            tokenizer.currentToken().type.enumType == .EQUAL) {
            let pos = tokenizer.currentToken().position
            let text = tokenizer.currentToken().text
            tokenizer.nextToken()
            result = BinaryExpr(pos, text, leftChild: result, rightChild: parseExpr())
        }
        
        
        return result
    }
    
    private func parseExpr() -> Expression?  {
        var result = parseTerm()
        if (result == nil) {
            return nil
        }
        
        while(tokenizer.currentToken().type.enumType == .PLUS || tokenizer.currentToken().type.enumType == .MINUS) {
            let pos = tokenizer.currentToken().position
            let text = tokenizer.currentToken().text
            tokenizer.nextToken()
            result = BinaryExpr(pos, text, leftChild: result, rightChild: parseTerm())
        }
       
        return result
    }
    
    private func parseTerm() -> Expression? {
        var result = parseFactor()
        if (result == nil) {
            return nil
        }
            
        while(tokenizer.currentToken().type.enumType == .MULT || tokenizer.currentToken().type.enumType == .DIV) {
            let pos = tokenizer.currentToken().position
            let text = tokenizer.currentToken().text
            tokenizer.nextToken()
            result = BinaryExpr(pos, text, leftChild: result, rightChild: parseFactor())
        }
        
        return result
    }
    
    private func parseFactor() -> Expression? {
        switch tokenizer.currentToken().type.enumType {
        case .ID:
            let result = IDExpr(name: tokenizer.currentToken().text, tokenizer.currentToken().position)
            tokenizer.nextToken()
            return result
        case .INT:
            let result = IntegerExp(value: UInt64(tokenizer.currentToken().value)!, tokenizer.currentToken().position)
            tokenizer.nextToken()
            return result
        case .DOUBLE:
            let result = DoubleExp(value: Double(tokenizer.currentToken().value)!, tokenizer.currentToken().position)
            tokenizer.nextToken()
            return result
        case .L_BRACKET:
            tokenizer.nextToken()
            let result = parseBoolExpr()
            if (result == nil) {
                return nil
            }
            if !require(getType(")")) {
                return nil
            }
            tokenizer.nextToken()
            return result
        default:
            print("Unknown symbol in expression")
            return nil
        }
    }
    

    private var separatorIndexes = [Int]()
    func getTreeAsStr(_ expr: Expression? = nil,_ tabNumber: Int = 0) -> String {
        if (self.root == nil) {
            return ""
        }
        let expr:Expression! = expr ?? self.root!
        var result = "⎬\(expr.text)"
        
        if(expr.leftChild != nil) {
            result += "\n";
            for i in 0...tabNumber {
                result += ((separatorIndexes.index(of: i)) != nil) ? "⎪" : " "
            }
            if(expr.leftChild?.leftChild != nil) {
                separatorIndexes.append(tabNumber + 1)
            }
            result += getTreeAsStr(expr.leftChild!, tabNumber + 1)
        }
        if(expr.rightChild != nil) {
            result += "\n";
            for i in 0...tabNumber {
                result += ((separatorIndexes.index(of: i)) != nil) ? "⎪" : " "
            }
            if let index = (separatorIndexes.index(of: tabNumber + 1)) {
                separatorIndexes.remove(at: index)
            }
            result += getTreeAsStr(expr.rightChild!, tabNumber + 1)
        }
        
        
        return result
    }
}
