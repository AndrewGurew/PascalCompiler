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
    private var testBlock:StatementNode?
    
    init(tokenizer: Tokenizer) {
        self.tokenizer = tokenizer
    }
    
    private func require(_ token: TokenType) {
        if(token != tokenizer.currentToken().type) {
            errorMessages.append("Expected: \(token.rawValue) in \(tokenizer.currentToken().position) before \(tokenizer.currentToken().text)")
            print("Expected \(token.rawValue) in \(tokenizer.currentToken().position) before \(tokenizer.currentToken().text)")
        }
    }
    
    private func parseProgram() -> StatementNode  {
        let declScope = parseDeclaration()
        require(.BEGIN)
        tokenizer.nextToken()
        let mainBlock = Block(tokenizer.currentToken().position, "Main Block", declScope)
        mainBlock.stmtList = parseStmtBlock()
        return mainBlock
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
            if(tokenizer.currentToken().type == .TYPE) {
                declarationScope.declList.update(other: parseTypeBlock())
            }
            if(tokenizer.currentToken().type == .BEGIN) {
                break
            }
        }
        return declarationScope.declList.isEmpty ? nil : declarationScope
    }
    
    private func parseVarBlock() -> [String: Declaration]? {
        var result = [String: Declaration]()
        tokenizer.nextToken()
    
        while (tokenizer.currentToken().type == .ID) {
            let IDs = getIndefenders()
            let type = parseType()
            for i in 0..<IDs.name.count {
                let decl = VarDecl(IDs.pos[i], IDs.name[i], type)
                result.update(other: [IDs.name[i]: decl])
            }
        }
        return result.isEmpty ? nil : result
    }
    
    private func parsConstBlock() -> [String: Declaration]? {
        var result = [String: Declaration]()
        tokenizer.nextToken()

        while(tokenizer.currentToken().type == .ID) {
            let IDs = getIndefenders()
            let expr = parseExpr()
            for i in 0..<IDs.name.count {
                let decl = ConstDecl(IDs.pos[i], IDs.name[i], expr!)
                result.update(other: [IDs.name[i]: decl])
            }
            require(.SEMICOLON)
            tokenizer.nextToken()
        }
        return result.isEmpty ? nil : result
    }
    
    private func parseTypeBlock() -> [String: Declaration]? {
        var result = [String: Declaration]()
        tokenizer.nextToken()
        while (tokenizer.currentToken().type == .ID) {
            let newType = tokenizer.currentToken()
            tokenizer.nextToken()
            require(.EQUAL)
            tokenizer.nextToken()
            let type = parseType()
            
            let decl = TypeDecl(newType.position, newType.text, type)
            result.update(other: [newType.text: decl])
        }
        
        return result.isEmpty ? nil : result
    }
    
    private func parseType() -> TypeNode {
        switch tokenizer.currentToken().type {
        case .RECORD:
            return parseRecordType()
        case .ARRAY:
            return parseArrayType()
        default:
            return parseSimpleType()
        }
    }
    
    private func parseRecordType() -> TypeNode {
        require(.RECORD)
        let position = tokenizer.currentToken().position
        let record = RecordType(position)
        for (key, value) in parseVarBlock()! {
            record.idList.update(other: [key: (value as! VarDecl).type])
        }
        
        require(.END)
        tokenizer.nextToken()
        require(.SEMICOLON)
        tokenizer.nextToken()
        
        return record
    }
    
    // Need to fix
    private func parseSimpleType() -> TypeNode {
        let token = tokenizer.currentToken()
        tokenizer.nextToken()
        require(.SEMICOLON)
        tokenizer.nextToken()
        
        switch token.type {
        case .INT:
            return SimpleType(token.position, .INT)
        case .DOUBLE:
            return SimpleType(token.position, .DOUBLE)
        default:
            return SimpleType(token.position, .ID)
        }
    }
    
    private func parseArrayType() -> TypeNode {
        require(.ARRAY)
        let position = tokenizer.currentToken().position
        tokenizer.nextToken()
        require(.LSQR_BRACKET)
        tokenizer.nextToken()
        let startIndex = parseExpr()!
        require(.D_DOT)
        tokenizer.nextToken()
        let finIndex = parseExpr()!
        require(.RSQR_BRACKET)
        tokenizer.nextToken()
        require(.OF)
        tokenizer.nextToken()
        let type = parseType()

        return ArrayType(position, type, startIndex, finIndex)
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
    
    private func parseStmtBlock() -> [StatementNode] {
        var stmtList = [StatementNode]()
        //tokenizer.nextToken()
        while (true) {
            if(tokenizer.currentToken().type == .END || tokenizer.currentToken().type == .UNTIL) {
                //tokenizer.nextToken()
                break
            }
            let stmt = parseStmt()
            stmtList.append(stmt!)
        }
        return stmtList
    }
    
    private func parseStmt() -> StatementNode? {
        switch tokenizer.currentToken().type {
        case .ID:
            return parseAssign()
        case .BEGIN:
            tokenizer.nextToken()
            let block = Block(tokenizer.currentToken().position, "Block")
            block.stmtList = parseStmtBlock()
            tokenizer.nextToken()
            return block
        case .IF:
            return parseIfElse()
        case .FOR:
            return parseFor()
        case .WHILE:
            return parseWhile()
        case .REPEAT:
            return parseRepeat()
        default:
            return nil
        }
    }
    
    private func parseRepeat() -> StatementNode {
        require(.REPEAT)
        let pos = tokenizer.currentToken().position
        let repeatBlock = Block(tokenizer.currentToken().position, "Repeat Block")
        tokenizer.nextToken()
        repeatBlock.stmtList = parseStmtBlock()
        require(.UNTIL)
        tokenizer.nextToken()
        let condition = parseExpr()!
        require(.SEMICOLON)
        tokenizer.nextToken()
        
        return RepeatStmt(pos, condition, repeatBlock)
    }
    
    private func parseIfElse() -> StatementNode {
        require(.IF)
        let pos = tokenizer.currentToken().position
        tokenizer.nextToken()
        let condition = parseExpr()
        require(.THEN)
        tokenizer.nextToken()
        let stmtNode = parseStmt()!
        
        var elseNode: StatementNode? = nil
        if(tokenizer.currentToken().type == .ELSE) {
            tokenizer.nextToken()
            elseNode = parseStmt()
        }
        return IfElseStmt(pos, condition!, stmtNode, elseNode)
    }
    
    private func parseAssign(_ parentType: TokenType = .BEGIN) -> StatementNode {
        require(.ID)
        let pos = tokenizer.currentToken().position
        let id = tokenizer.currentToken().text
        tokenizer.nextToken()
        require(.ASSIGN)
        tokenizer.nextToken()
        let expr = parseExpr()!
        if(parentType == .BEGIN) {
            require(.SEMICOLON)
            tokenizer.nextToken()
        }
        return AssignStmt(pos, expr, id)
    }
    
    func parseFor() -> StatementNode {
        require(.FOR)
        let position = tokenizer.currentToken().position
        tokenizer.nextToken()
        let startValue = parseAssign(.FOR)
        require(.TO)
        tokenizer.nextToken()
        let finishValue = parseExpr()!
        require(.DO)
        tokenizer.nextToken()
        let forNode = parseStmt()!
        return ForStmt(position, startValue, finishValue, forNode)
    }
    
    func parseWhile() -> StatementNode {
        require(.WHILE)
        let position = tokenizer.currentToken().position
        tokenizer.nextToken()
        let condition = parseExpr()!
        require(.DO)
        tokenizer.nextToken()
        let whileNode = parseStmt()!
        return WhileStmt(position, condition, whileNode)
    }
    
    private func parseExpr() -> Expression? {
        var result = parseSimpleExpr()
        if(result == nil) {
            return nil
        }
        while(tokenizer.currentToken().type == .MORE || tokenizer.currentToken().type == .LESS ||
            tokenizer.currentToken().type == .MORE_EQUAL || tokenizer.currentToken().type == .LESS_EQUAL ||
            tokenizer.currentToken().type == .EQUAL) {
            let pos = tokenizer.currentToken().position
            let text = tokenizer.currentToken().text
            tokenizer.nextToken()
            result = BinaryExpr(pos, text, leftChild: result!, rightChild: parseSimpleExpr()!)
        }
        
        return result
    }
    
    private func parseSimpleExpr() -> Expression?  {
        var result = parseTerm()
        if (result == nil) {
            return nil
        }
        
        while(tokenizer.currentToken().type == .PLUS || tokenizer.currentToken().type == .MINUS ||
            tokenizer.currentToken().type == .OR) {
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
            
        while(tokenizer.currentToken().type == .MULT || tokenizer.currentToken().type == .DIV ||
            tokenizer.currentToken().type == .AND) {
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
            let result = parseExpr()
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
    
    public func testExpressions() -> String {
        return drawExprTree(parseExpr())
    }
    
    public func testAllStmt() -> String {
        self.testBlock = parseProgram()
        return drawBlockTree(self.testBlock)
    }
    
    public func testStmt() -> String {
        self.testDecl = parseDeclaration()
        return drawDeclTree(self.testDecl)
    }
}

