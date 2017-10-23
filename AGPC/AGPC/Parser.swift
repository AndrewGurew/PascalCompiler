//
//  Parser.swift
//  AGPC
//
//  Created by Andrey Gurev on 13.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

class Parser {
    private var tokenizer:Tokenizer
    
    init(tokenizer: Tokenizer) {
        self.tokenizer = tokenizer
    }
    
    private func parseBlock() -> StatementNode? {
        return parseStatements()
    }
    
    private func parseIfElse() -> StatementNode {
        let position = tokenizer.currentToken().position
        
        tokenizer.nextToken()
        let cond = parseBoolExpr()
        tokenizer.nextToken()
        let block = parseBlock()
        tokenizer.nextToken()
        if(tokenizer.currentToken().type.enumType == .ELSE) {
            tokenizer.nextToken()
            return IFElseStmt(position, "ifelseStmt", cond!, block!, parseBlock())
        }
        
        return IFElseStmt(position, "ifelseStmt", cond!, block!, nil)
    }
    
    private func parseStatements() -> StatementNode? {
        let token = tokenizer.currentToken()
        switch token.type.enumType {
        case .IF:
            return parseIfElse()
        case .BEGIN:
            return parseBlock()
        default:
            return nil
        }
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
        if(result == nil) {
            return nil
        }
        while(tokenizer.currentToken().type.enumType == .MORE || tokenizer.currentToken().type.enumType == .LESS ||
            tokenizer.currentToken().type.enumType == .MORE_EQUAL || tokenizer.currentToken().type.enumType == .LESS_EQUAL ||
            tokenizer.currentToken().type.enumType == .EQUAL) {
            let pos = tokenizer.currentToken().position
            let text = tokenizer.currentToken().text
            tokenizer.nextToken()
                result = BinaryExpr(pos, text, leftChild: result!, rightChild: parseExpr()!)
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
            result = BinaryExpr(pos, text, leftChild: result!, rightChild: parseTerm()!)
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
            result = BinaryExpr(pos, text, leftChild: result!, rightChild: parseFactor()!)
        }
        
        return result
    }
    
    private func parseFactor() -> Expression? {
        switch tokenizer.currentToken().type.enumType {
        case .MINUS, .PLUS:
            let operation = tokenizer.currentToken()
            tokenizer.nextToken()
            return UnaryExpr(operation.position, operation.text, child: parseTerm()!)
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
    func getExprTreeAsStr(_ expr: Expression? = nil,_ tabNumber: Int = 0) -> String {
        if(expr == nil) {
            return ""
        }
        let expr:Expression! = expr!
        var result = "⎬\(expr.text)"
        
        if let binaryExpr = expr as? BinaryExpr {
            // Draw left
            result += "\n";
            for i in 0...tabNumber {
                result += ((separatorIndexes.index(of: i)) != nil) ? "⎪" : " "
            }
            if((binaryExpr.leftChild as? BinaryExpr) != nil) {
                separatorIndexes.append(tabNumber + 1)
            }
            result += getExprTreeAsStr(binaryExpr.leftChild, tabNumber + 1)
            
            //Draw right
            result += "\n";
            for i in 0...tabNumber {
                result += ((separatorIndexes.index(of: i)) != nil) ? "⎪" : " "
            }
            if let index = separatorIndexes.index(of: tabNumber + 1) {
                separatorIndexes.remove(at: index)
            }
            result += getExprTreeAsStr(binaryExpr.rightChild, tabNumber + 1)
        }
        
        if let unaryExpr = expr as? UnaryExpr {
            result += "\n";
            for i in 0...tabNumber {
                result += ((separatorIndexes.index(of: i)) != nil) ? "⎪" : " "
            }
            result += getExprTreeAsStr(unaryExpr.child, tabNumber + 1)
        }
        
        return result
    }
    
    public func testExpressions() -> String {
        return getExprTreeAsStr(parseBoolExpr())
    }
}

