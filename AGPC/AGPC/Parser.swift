//
//  Parser.swift
//  AGPC
//
//  Created by Andrey Gurev on 13.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

extension Dictionary {
    mutating func update(other:Dictionary?) {
        if(other != nil) {
            for (key,value) in other! {
                self.updateValue(value, forKey:key)
            }
        }
    }
}

class Parser {
    private var tokenizer:Tokenizer
    private var testDecl:DeclarationScope?
    
    init(tokenizer: Tokenizer) {
        self.tokenizer = tokenizer
        self.testDecl = parseDeclaration()
        print(drawDeclTree(self.testDecl, 0))
        
    }
    
    private func require(_ token: TokenType) -> Bool {
        if(token.enumType != tokenizer.currentToken().type.enumType) {
            print("Expected: \(token.strType) in \(tokenizer.currentToken().position)")
            return false
        }
        return true
    }
    
    private func require(_ token: TokenEnum) -> Bool {
        if(token != tokenizer.currentToken().type.enumType) {
            print("Expected another token on \(tokenizer.currentToken().position)")
            return false
        }
        return true
    }
    
    private func parseDeclaration() -> DeclarationScope? {
        let declarationScope = DeclarationScope()
        for _ in 0..<tokenizer.lexems.count {
            if(tokenizer.currentToken().type.enumType == .VAR) {
                tokenizer.nextToken()
                declarationScope.declList.update(other: parseVarBlock())
            }
        }

        return declarationScope.declList.isEmpty ? nil : declarationScope
    }
    
    private func parseVarBlock() -> [String: Declaration]? {
        var result = [String: Declaration]()
        while (tokenizer.currentToken().type.enumType == .ID) {
            let IDs = getIndefenders()
            tokenizer.nextToken()
            let identType = IdentType(tokenizer.currentToken().position, tokenizer.currentToken().type.enumType)
            for i in 0..<IDs.0.count {
                let decl = VarType(IDs.pos[i], IDs.name[i], identType)
                result.update(other: [IDs.name[i]: decl])
            }
            tokenizer.nextToken()
            tokenizer.nextToken()
        }
        return result.isEmpty ? nil : result
    }
    
    private func getIndefenders() -> (name: [String], pos: [(Int, Int)]) {
        var result = [String]()
        var positions = [(Int, Int)]()
        while (tokenizer.currentToken().type.enumType == .ID) {
            result.append(tokenizer.currentToken().text)
            positions.append(tokenizer.currentToken().position)
            tokenizer.nextToken()
            if(tokenizer.currentToken().type.enumType == .COMMA) {
                tokenizer.nextToken()
            }
        }
        
        return (result, positions)
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
    
    func drawDeclTree(_ a: DeclarationScope? = nil,_ tabNumber: Int = 0) -> String {
        if(a == nil) {
            return ""
        }
        let expr:DeclarationScope! = a!
        var result = "⎬Declarations"
        for (key,value) in expr.declList {
            result += "\n ⎬\(key) - \(value.type.type.rawValue)(\(value.declType.rawValue))"
        }
        return result
    }
    
    private var separatorIndexes = [Int]()
    func drawExprTree(_ expr: Expression? = nil,_ tabNumber: Int = 0) -> String {
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
            result += drawExprTree(binaryExpr.leftChild, tabNumber + 1)
            
            //Draw right
            result += "\n";
            for i in 0...tabNumber {
                result += ((separatorIndexes.index(of: i)) != nil) ? "⎪" : " "
            }
            if let index = separatorIndexes.index(of: tabNumber + 1) {
                separatorIndexes.remove(at: index)
            }
            result += drawExprTree(binaryExpr.rightChild, tabNumber + 1)
        }
        
        if let unaryExpr = expr as? UnaryExpr {
            result += "\n";
            for i in 0...tabNumber {
                result += ((separatorIndexes.index(of: i)) != nil) ? "⎪" : " "
            }
            result += drawExprTree(unaryExpr.child, tabNumber + 1)
        }
        
        return result
    }
    
    public func testExpressions() -> String {
        return drawExprTree(parseBoolExpr())
    }
}

