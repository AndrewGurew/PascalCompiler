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
    }
    
    private func require(_ token: TokenType) {
        if(token != tokenizer.currentToken().type) {
            errorMessages.append("Expected: \(token.rawValue) in \(tokenizer.currentToken().position) before \(tokenizer.currentToken().text)")
        }
    }
    
    private func parseDeclaration() -> DeclarationScope? {
        let declarationScope = DeclarationScope()
        for _ in 0..<tokenizer.lexems.count {
            if(tokenizer.currentToken().type == .VAR) {
                declarationScope.declList.update(other: parseVarBlock())
            }
            if(tokenizer.currentToken().type == .CONST) {
                declarationScope.declList.update(other: parsConstBlock())
            }
        }
        return declarationScope.declList.isEmpty ? nil : declarationScope
    }
    
    private func parseVarBlock() -> [String: Declaration]? {
        var result = [String: Declaration]()
        tokenizer.nextToken()
    
        while (tokenizer.currentToken().type == .ID) {
            let IDs = getIndefenders()
            let identType = IdentType(tokenizer.currentToken().position, tokenizer.currentToken().type)
            for i in 0..<IDs.name.count {
                let decl = VarDecl(IDs.pos[i], IDs.name[i], identType)
                result.update(other: [IDs.name[i]: decl])
            }
            tokenizer.nextToken()
            require(.SEMICOLON)
            tokenizer.nextToken()
        }
        return result.isEmpty ? nil : result
    }
    
    private func parsConstBlock() -> [String: Declaration]? {
        var result = [String: Declaration]()
        tokenizer.nextToken()

        while(tokenizer.currentToken().type == .ID) {
            let IDs = getIndefenders()
            let expr = parseBoolExpr()
            for i in 0..<IDs.name.count {
                let decl = ConstDecl(IDs.pos[i], IDs.name[i], expr!)
                result.update(other: [IDs.name[i]: decl])
            }
           // bool do next tokenizer.nextToken()
            require(.SEMICOLON)
            tokenizer.nextToken()
        }
        return result.isEmpty ? nil : result
    }
    
    private func getIndefenders() -> (name: [String], pos: [(Int, Int)]) {
        var result = [String]()
        var positions = [(Int, Int)]()
        while (tokenizer.currentToken().type == .ID) {
            result.append(tokenizer.currentToken().text)
            positions.append(tokenizer.currentToken().position)
            tokenizer.nextToken()
            if(tokenizer.currentToken().type == .COMMA) {
                tokenizer.nextToken()
                require(.ID)
            } else {
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
        while(tokenizer.currentToken().type == .MORE || tokenizer.currentToken().type == .LESS ||
            tokenizer.currentToken().type == .MORE_EQUAL || tokenizer.currentToken().type == .LESS_EQUAL ||
            tokenizer.currentToken().type == .EQUAL) {
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
        
        while(tokenizer.currentToken().type == .PLUS || tokenizer.currentToken().type == .MINUS) {
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
            
        while(tokenizer.currentToken().type == .MULT || tokenizer.currentToken().type == .DIV) {
            let pos = tokenizer.currentToken().position
            let text = tokenizer.currentToken().text
            tokenizer.nextToken()
            result = BinaryExpr(pos, text, leftChild: result!, rightChild: parseFactor()!)
        }
        
        return result
    }
    
    private func parseFactor() -> Expression? {
        switch tokenizer.currentToken().type {
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
            require(.R_BRACKET)
  
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
            if value is VarDecl {
                result += "\n ⎬\(key) - \((value as! VarDecl).type.type.rawValue)(\(value.declType.rawValue))"
            }
            else {
                var exprTree = drawExprTree((value as! ConstDecl).value, key.length + 4)
                exprTree.removeFirst()
                result += "\n ⎬\(key) - \(exprTree)(\(value.declType.rawValue))"
            }
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
    
    public func testStmt() -> String {
        self.testDecl = parseDeclaration()
        return drawDeclTree(self.testDecl, 0)
    }
}

