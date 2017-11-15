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
                if self.index(forKey: key) != nil {
                    errorMessages.append("Duplicate declaration of \"\(key)\"")
                }
                self.updateValue(value, forKey:key)
            }
        }
    }
}

class Parser {
    private var tokenizer:Tokenizer
    private var testDecl:DeclarationScope?
    private var testBlock:StatementNode?
    
    var varStack = [DeclarationScope]()
    
//    private func check(in dict: [String: Declaration], name: String) {
//        if dict.index(forKey: name) != nil {
//            errorMessages.append("Duplicate declaration of \"\(name)\"")
//        }
//    }
    
    private func check(name: String) {
        if varStack.isEmpty {
            errorMessages.append("Unknown identifier \(name)")
            return
        }
        for i in varStack.count - 1...0 {
            if varStack[i].declList.index(forKey: name) != nil {
                return
            }
        }
        errorMessages.append("Unknown identifier \(name)")
    }
    
    init(tokenizer: Tokenizer) {
        self.tokenizer = tokenizer
    }
    
    private func require(_ token: TokenType) {
        if(token != tokenizer.currentToken().type) {
            errorMessages.append("Expected: \(token.rawValue) in \(tokenizer.currentToken().position) before \(tokenizer.currentToken().text)")
        }
    }
    
    private func require(_ tokens: [TokenType]) {
        var result = ""
        for token in tokens { result += token.rawValue + " or " }
        result = result[0..<result.length - 4]
        
        if (tokens.index(of: tokenizer.currentToken().type) == nil) {
            errorMessages.append("Expected \(result) in \(tokenizer.currentToken().position) before \(tokenizer.currentToken().text)")
        }
    }
    
    private func parseProgram(_ text: String) -> StatementNode  {
        var appended = false
        let pos = tokenizer.currentToken().position
        let declScope = parseDeclaration()
        if (declScope != nil) {
            varStack.append(declScope!);
            appended = true
        }
        require(.BEGIN)
        tokenizer.nextToken()
        let stamts = parseStmtBlock()
        if (appended) {
            varStack.removeLast()
        }
        return Block(pos, text, declScope, stamts)
    }
    
    private func parseDeclaration() -> DeclarationScope? {
        let declarationScope = DeclarationScope()
        while(true) {
            switch(tokenizer.currentToken().type) {
            case .VAR:
                declarationScope.declList.update(other: parseVarBlock())
            case .CONST:
                declarationScope.declList.update(other: parsConstBlock())
            case .TYPE:
                declarationScope.declList.update(other: parseTypeBlock())
            case .PROCEDURE, .FUNCTION:
                declarationScope.declList.update(other: parseProc())
            default:
                require([.BEGIN, .ENDOFFILE])
                return declarationScope.declList.isEmpty ? nil : declarationScope
            }
        }
    }
    
    private func parseVarBlock() -> [String: Declaration]? {
        var result = [String: Declaration]()
        tokenizer.nextToken()
        while (tokenizer.currentToken().type == .ID) {
            let Identifiers = getIdentifiers()
            let type = parseType()
            for id in Identifiers {
                result.update(other: [id.name: VarDecl(id.pos, id.name, type)])
            }
            require(.SEMICOLON)
            tokenizer.nextToken()
        }
        return result.isEmpty ? nil : result
    }
    
    private func parsConstBlock() -> [String: Declaration]? {
        var result = [String: Declaration]()
        tokenizer.nextToken()
        while(tokenizer.currentToken().type == .ID) {
            let Identifiers = getIdentifiers()
            let expr = parseExpr()
            for id in Identifiers{
                result.update(other: [id.name: ConstDecl(id.pos, id.name, expr!)])
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
            let decl = TypeDecl(newType.position, newType.text, parseType())
            result.update(other: [newType.text: decl])
            require(.SEMICOLON)
            tokenizer.nextToken()
        }
        
        return result.isEmpty ? nil : result
    }
    
    private func parseParams() -> [String: Declaration] {
        var result = [String: Declaration]()
        tokenizer.nextToken()
        while (tokenizer.currentToken().type == .ID) {
            let Identifiers = getIdentifiers()
            let type = parseType()
            for id in Identifiers {
                result.update(other: [id.name: VarDecl(id.pos, id.name, type)])
            }
            
            if(tokenizer.currentToken().type == .R_BRACKET) {
                break;
            } else {
                require(.SEMICOLON)
                tokenizer.nextToken()
            }
        }
        return result
    }
    
    private func parseProc() -> [String: Declaration]? {
        let isFunction = tokenizer.currentToken().type == .FUNCTION
        let position = tokenizer.currentToken().position
        var text = "Procedure"
        var returnType: TypeNode? = nil
        tokenizer.nextToken()
        require(.ID)
        let procName = tokenizer.currentToken().text
        
        tokenizer.nextToken()
        require(.L_BRACKET)
        let params = parseParams()
        require(.R_BRACKET)
        tokenizer.nextToken()
        if(isFunction) {
            require(.COLON)
            tokenizer.nextToken()
            returnType = parseSimpleType()
            require(.SEMICOLON)
            text = "Function"
        } else {
            require(.SEMICOLON)
        }
        tokenizer.nextToken()
        
        if(tokenizer.currentToken().type == .FORWARD) {
            tokenizer.nextToken()
            require(.SEMICOLON)
            tokenizer.nextToken()
            return [procName: ProcFuncDecl(position, text, Block(tokenizer.currentToken().position, "Foward", nil, []), params, returnType)]
        } else {
            let block = parseProgram("Procedure Block")
            require(.END)
            tokenizer.nextToken()
            return [procName: ProcFuncDecl(position, text, block, params, returnType)]
        }
        
    }
    
    private func parseType() -> TypeNode {
        let token = tokenizer.currentToken().type
        switch token {
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
        
        return record
    }
    
    // Need to fix
    private func parseSimpleType() -> TypeNode {
        let token = tokenizer.currentToken()
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
    
    private func getIdentifiers() -> [(name: String, pos: (Int, Int))] {
        var result = [(name: String, pos: (Int, Int))]()
        while (tokenizer.currentToken().type == .ID) {
            result.append((tokenizer.currentToken().text, tokenizer.currentToken().position))
            tokenizer.nextToken()
            if(tokenizer.currentToken().type == .COMMA) {
                tokenizer.nextToken()
                require(.ID)
            } else {
                tokenizer.nextToken()
            }
        }
        
        return result
    }
    
    private func parseStmtBlock() -> [StatementNode] {
        var stmtList = [StatementNode]()
        while (true) {
            let stmt = parseStmt()
            if(stmt == nil) {
                require([.END, .UNTIL])
                break
            } else {
                stmtList.append(stmt!)
            }
        }
        return stmtList
    }
    
    private func parseStmt() -> StatementNode? {
        switch tokenizer.currentToken().type {
        case .ID:
            return parseID()
        case .BEGIN:
            tokenizer.nextToken()
            let block = Block(tokenizer.currentToken().position, "Block", nil, parseStmtBlock())
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
           // require([.ID, .BEGIN, .IF, .FOR, .WHILE, .REPEAT])
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
    
    private func parseID(_ parentType: TokenType = .BEGIN) -> StatementNode {
        require(.ID)
        let pos = tokenizer.currentToken().position
        let id = tokenizer.currentToken().text
        check(name: id)
        tokenizer.nextToken()
        if (tokenizer.currentToken().type == .L_BRACKET) {
            return parseCall(pos, id)
        }
        else {
       //else if (tokenizer.currentToken().type == .ASSIGN) {
            return parseAssign(pos, id, parentType)
        }
    }
    
    private func parseCall(_ pos: (Int, Int),_ name: String,_ inExpr: Bool = false) -> StatementNode {
        require(.L_BRACKET)
        tokenizer.nextToken()
        var paramList = [Expression]()
        while (tokenizer.currentToken().type != .R_BRACKET) {
            paramList.append(parseExpr()!)
            if(tokenizer.currentToken().type == .COMMA) {
                tokenizer.nextToken()
            }
        }
        require(.R_BRACKET)
        if(!inExpr) {
            tokenizer.nextToken()
            require(.SEMICOLON)
        }
        tokenizer.nextToken()
        return ProcFuncCall(pos, name, paramList)
    }
    
    private func parseAssign(_ pos: (Int, Int),_ name: String,_ parentType: TokenType = .BEGIN) -> StatementNode {
        require(.ASSIGN)
        tokenizer.nextToken()
        let expr = parseExpr()!
        if(parentType == .BEGIN) {
            require(.SEMICOLON)
            tokenizer.nextToken()
        }
        return AssignStmt(pos, expr, name)
    }
    
    func parseFor() -> StatementNode {
        require(.FOR)
        let position = tokenizer.currentToken().position
        tokenizer.nextToken()
        let startValue = parseID(.FOR)
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
        if(result == nil) { return nil }
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
        if (result == nil) { return nil }
        
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
        if (result == nil) { return nil }
            
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
            return parseDescription()
        case .INT:
            let result = IntegerExpr(value: UInt64(tokenizer.currentToken().value)!, tokenizer.currentToken().position)
            tokenizer.nextToken()
            return result
        case .DOUBLE:
            let result = DoubleExpr(value: Double(tokenizer.currentToken().value)!, tokenizer.currentToken().position)
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
            errorMessages.append("Unexpected symbol in \(tokenizer.currentToken().text) in \(tokenizer.currentToken().position)")
            return nil
        }
    }
    
    private func parseDescription() -> Expression {
        require(.ID)
        let name = tokenizer.currentToken().text
        let pos = tokenizer.currentToken().position
        check(name: name)
        tokenizer.nextToken()
        if(tokenizer.currentToken().type == .L_BRACKET) {
            let funcCall = parseCall(pos, name, true)
            return FuncDesignator(pos,name, (funcCall as! ProcFuncCall).paramList)
        } else  {
            return IDExpr(name, pos)
        }
    }
    
    private func printErrors() -> String {
        var result = ""
        for error in errorMessages {
            result += error + "\n"
        }
        errorMessages.removeAll()
        return result
    }
    
    public func testExpressions() -> String {
        return printErrors() + drawExprTree(parseExpr())
    }
    
    public func testAllStmt() -> String {
        self.testBlock = parseProgram("Main block")
        return printErrors() + drawBlockTree(self.testBlock)
    }
    
    public func testStmt() -> String {
        self.testDecl = parseDeclaration()
        return printErrors() + drawDeclTree(self.testDecl)
    }
}

