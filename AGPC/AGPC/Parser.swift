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
    private var varStack = [DeclarationScope]()
    
    
    init(tokenizer: Tokenizer) {
        self.tokenizer = tokenizer
    }
    
    func parseProgram(_ text: String) throws -> StatementNode  {
        let pos = tokenizer.currentToken().position
        let declScope = try parseDeclaration()
        try require(.BEGIN)
        try tokenizer.nextToken()
        let stamts = try parseStmtBlock()
        varStack.removeLast()
        return Block(pos, text, declScope, stamts)
    }
    
    private func parseDeclaration() throws -> DeclarationScope? {
        let declarationScope = DeclarationScope()
        varStack.append(declarationScope);
        while(true) {
            varStack[varStack.count - 1] = declarationScope
            switch(tokenizer.currentToken().type) {
            case .VAR:
                try declarationScope.declList.update(other: parseVarBlock())
            case .CONST:
                try declarationScope.declList.update(other: parsConstBlock())
            case .TYPE:
                try declarationScope.declList.update(other: parseTypeBlock())
            case .PROCEDURE, .FUNCTION:
                try declarationScope.declList.update(other: parseProc())
            default:
                try require([.BEGIN, .ENDOFFILE])
                return declarationScope.declList.isEmpty ? nil : declarationScope
            }
        }
    }
    
    private func parseVarBlock() throws -> [String: Declaration]? {
        var result = [String: Declaration]()
        try tokenizer.nextToken()
        while (tokenizer.currentToken().type == .ID) {
            let Identifiers = try getIdentifiers()
            let type = try parseType()
            for id in Identifiers {
                try result.update(other: [id.name: VarDecl(id.pos, id.name, type)])
            }
            try require(.SEMICOLON)
            try tokenizer.nextToken()
        }
        return result.isEmpty ? nil : result
    }
    
    private func parsConstBlock() throws -> [String: Declaration]? {
        var result = [String: Declaration]()
        try tokenizer.nextToken()
        while(tokenizer.currentToken().type == .ID) {
            let Identifiers = try getIdentifiers()
            let expr = try parseExpr()
            
            for id in Identifiers{
                try result.update(other: [id.name: ConstDecl(id.pos, id.name, expr)])
            }
            try require(.SEMICOLON)
            try tokenizer.nextToken()
        }
        return result.isEmpty ? nil : result
    }
    
    private func parseTypeBlock() throws -> [String: Declaration]? {
        var result = [String: Declaration]()
        try tokenizer.nextToken()
        while (tokenizer.currentToken().type == .ID) {
            let newType = tokenizer.currentToken()
            try tokenizer.nextToken()
            try require(.EQUAL)
            try tokenizer.nextToken()
            let decl = TypeDecl(newType.position, newType.text, try parseType())
            try result.update(other: [newType.text: decl])
            try require(.SEMICOLON)
            try tokenizer.nextToken()
        }
        
        return result.isEmpty ? nil : result
    }
    
    private func parseParams() throws -> [String: Declaration] {
        var result = [String: Declaration]()
        try tokenizer.nextToken()
        while (tokenizer.currentToken().type == .ID) {
            let Identifiers = try getIdentifiers()
            let type = try parseType()
            for id in Identifiers {
                try result.update(other: [id.name: VarDecl(id.pos, id.name, type)])
            }
            
            if(tokenizer.currentToken().type == .R_BRACKET) {
                break;
            } else {
                try require(.SEMICOLON)
                try tokenizer.nextToken()
            }
        }
        return result
    }
    
    private func parseProc() throws -> [String: Declaration]? {
        let isFunction = tokenizer.currentToken().type == .FUNCTION
        let position = tokenizer.currentToken().position
        var text = "Procedure"
        var returnType: TypeNode? = nil
        try tokenizer.nextToken()
        try require(.ID)
        let procName = tokenizer.currentToken().text
        
        try tokenizer.nextToken()
        try require(.L_BRACKET)
        let params = try parseParams()
        let paramsScope = DeclarationScope()
        paramsScope.declList = params
        varStack.append(paramsScope)
        try require(.R_BRACKET)
        try tokenizer.nextToken()
        if(isFunction) {
            try require(.COLON)
            try tokenizer.nextToken()
            returnType = try parseSimpleType()
            try require(.SEMICOLON)
            text = "Function"
        } else {
            try require(.SEMICOLON)
        }
        try tokenizer.nextToken()
        
        if(tokenizer.currentToken().type == .FORWARD) {
            try tokenizer.nextToken()
            try require(.SEMICOLON)
            try tokenizer.nextToken()
            return [procName: ProcFuncDecl(position, text, Block(tokenizer.currentToken().position, text, nil, []), params, returnType, true)]
        } else {
            let block = try parseProgram("Procedure Block")
            try require(.END)
            try tokenizer.nextToken()
            varStack.removeLast()
            return [procName: ProcFuncDecl(position, text, block, params, returnType)]
        }
        
    }
    
    private func parseType() throws -> TypeNode {
        let token = tokenizer.currentToken().type
        switch token {
        case .RECORD:
            return try parseRecordType()
        case .ARRAY:
            return try parseArrayType()
        default:
            return try parseSimpleType()
        }
    }
    
    private func parseRecordType() throws -> TypeNode {
        try require(.RECORD)
        let position = tokenizer.currentToken().position
        let record = RecordType(position)
        for (key, value) in try parseVarBlock()! {
            try record.idList.update(other: [key: (value as! VarDecl).type])
        }
        try require(.END)
        try tokenizer.nextToken()
        
        return record
    }

    private func parseSimpleType() throws -> TypeNode {
        let token = tokenizer.currentToken()
        try tokenizer.nextToken()
        switch token.type {
        case .INT:
            return SimpleType(token.position, .INT)
        case .DOUBLE:
            return SimpleType(token.position, .DOUBLE)
        default:
            return SimpleType(token.position, .ID)
        }
    }
    
    private func parseArrayType() throws -> TypeNode {
        try require(.ARRAY)
        let position = tokenizer.currentToken().position
        try tokenizer.nextToken()
        try require(.LSQR_BRACKET)
        try tokenizer.nextToken()
        let startIndex = try parseExpr()
        try require(.D_DOT)
        try tokenizer.nextToken()
        let finIndex = try parseExpr()
        try require(.RSQR_BRACKET)
        try tokenizer.nextToken()
        try require(.OF)
        try tokenizer.nextToken()
        let type = try parseType()

        return ArrayType(position, type, startIndex, finIndex)
    }
    
    private func getIdentifiers() throws -> [(name: String, pos: (Int, Int))] {
        var result = [(name: String, pos: (Int, Int))]()
        while (tokenizer.currentToken().type == .ID) {
            result.append((tokenizer.currentToken().text, tokenizer.currentToken().position))
            try tokenizer.nextToken()
            if(tokenizer.currentToken().type == .COMMA) {
                try tokenizer.nextToken()
                try require(.ID)
            } else {
                try tokenizer.nextToken()
            }
        }
        
        return result
    }
    
    private func parseStmtBlock() throws -> [StatementNode] {
        var stmtList = [StatementNode]()
        while (true) {
            let stmt = try parseStmt()
            if(stmt == nil) {
                try require([.END, .UNTIL])
                break
            } else {
                stmtList.append(stmt!)
            }
        }
        return stmtList
    }
    
    private func parseStmt() throws -> StatementNode? {
        switch tokenizer.currentToken().type {
        case .ID:
            return try parseID()
        case .BEGIN:
            try tokenizer.nextToken()
            let block = Block(tokenizer.currentToken().position, "Block", nil, try parseStmtBlock())
            try tokenizer.nextToken()
            return block
        case .IF:
            return try parseIfElse()
        case .FOR:
            return try parseFor()
        case .WHILE:
            return try parseWhile()
        case .REPEAT:
            return try parseRepeat()
        default:
           // try require([.ID, .BEGIN, .IF, .FOR, .WHILE, .REPEAT])
            return nil
        }
    }
    
    private func parseRepeat() throws -> StatementNode {
        try require(.REPEAT)
        let pos = tokenizer.currentToken().position
        let repeatBlock = Block(tokenizer.currentToken().position, "Repeat Block")
        try tokenizer.nextToken()
        repeatBlock.stmtList = try parseStmtBlock()
        try require(.UNTIL)
        try tokenizer.nextToken()
        let condition = try parseExpr()
        try require(.SEMICOLON)
        try tokenizer.nextToken()
        
        return RepeatStmt(pos, condition, repeatBlock)
    }
    
    private func parseIfElse() throws -> StatementNode {
        try require(.IF)
        let pos = tokenizer.currentToken().position
        try tokenizer.nextToken()
        
        let condition = try parseExpr()
        
        try require(.THEN)
        try tokenizer.nextToken()
        let stmtNode = try parseStmt()!
        
        var elseNode: StatementNode? = nil
        if(tokenizer.currentToken().type == .ELSE) {
            try tokenizer.nextToken()
            elseNode = try parseStmt()
        }
        return IfElseStmt(pos, condition, stmtNode, elseNode)
    }
    
    private func parseID(_ parentType: TokenType = .BEGIN) throws -> StatementNode {
        try require(.ID)
        let pos = tokenizer.currentToken().position
        let id = tokenizer.currentToken().text
        //check(name: id)
        try tokenizer.nextToken()
        if (tokenizer.currentToken().type == .L_BRACKET) {
            return try parseCall(pos, id)
        }
        else {
       //else if (tokenizer.currentToken().type == .ASSIGN) {
            return try parseAssign(pos, id, parentType)
        }
    }
    
    private func parseCall(_ pos: (Int, Int),_ name: String,_ inExpr: Bool = false) throws -> StatementNode {
        try require(.L_BRACKET)
        try tokenizer.nextToken()
        var paramList = [Expression]()
        while (tokenizer.currentToken().type != .R_BRACKET) {
            let expr = try parseExpr()
            paramList.append(expr)
            if(tokenizer.currentToken().type == .COMMA) {
                try tokenizer.nextToken()
            }
        }
        try require(.R_BRACKET)
        if(!inExpr) {
            try tokenizer.nextToken()
            try require(.SEMICOLON)
        }
        
        try tokenizer.nextToken()
        if(name.lowercased() == "write" || name.lowercased() == "writeln") {
            return WritelnCall(pos, name, paramList)
        } else {
            let result = ProcFuncCall(pos, name, paramList)
            try checkCall(Of: result)
            return result
        }
    }
    
    private func parseAssign(_ pos: (Int, Int),_ name: String,_ parentType: TokenType = .BEGIN) throws -> StatementNode {
        try require(.ASSIGN)
        try tokenizer.nextToken()
        let expr = try parseExpr()
        
        if(parentType == .BEGIN) {
            try require(.SEMICOLON)
            try tokenizer.nextToken()
        }
        try requireType(expr.type!, getIDType(name: name, pos)! , pos)
        return AssignStmt(pos, expr, name)
    }
    
    func parseFor() throws -> StatementNode {
        try require(.FOR)
        let position = tokenizer.currentToken().position
        try tokenizer.nextToken()
        let startValue = try parseID(.FOR)
        try require(.TO)
        try tokenizer.nextToken()
        let finishValue = try parseExpr()
        try require(.DO)
        try tokenizer.nextToken()
        let forNode = try parseStmt()!
        return ForStmt(position, startValue, finishValue, forNode)
    }
    
    func parseWhile() throws -> StatementNode {
        try require(.WHILE)
        let position = tokenizer.currentToken().position
        try tokenizer.nextToken()
        let condition = try parseExpr()
        try require(.DO)
        try tokenizer.nextToken()
        let whileNode = try parseStmt()!
        return WhileStmt(position, condition, whileNode)
    }
    
    private func parseExpr() throws -> Expression {
        var result = try parseSimpleExpr()
        
        while(tokenizer.currentToken().type == .MORE || tokenizer.currentToken().type == .LESS ||
            tokenizer.currentToken().type == .MORE_EQUAL || tokenizer.currentToken().type == .LESS_EQUAL ||
            tokenizer.currentToken().type == .EQUAL) {
            let pos = tokenizer.currentToken().position
            let text = tokenizer.currentToken().text
            try tokenizer.nextToken()
            result = try BinaryExpr(pos, text, leftChild: result, rightChild: try parseSimpleExpr())
        }
        
        return result
    }
    
    private func parseSimpleExpr() throws -> Expression  {
        var result = try parseTerm()
        
        while(tokenizer.currentToken().type == .PLUS || tokenizer.currentToken().type == .MINUS ||
            tokenizer.currentToken().type == .OR) {
            let pos = tokenizer.currentToken().position
            let text = tokenizer.currentToken().text
            try tokenizer.nextToken()
            result = try BinaryExpr(pos, text, leftChild: result, rightChild: try parseTerm())
        }
       
        return result
    }
    
    private func parseTerm() throws -> Expression {
        var result = try parseFactor()
        while(tokenizer.currentToken().type == .MULT || tokenizer.currentToken().type == .DIV ||
            tokenizer.currentToken().type == .AND) {
            let pos = tokenizer.currentToken().position
            let text = tokenizer.currentToken().text
            try tokenizer.nextToken()
            result = try BinaryExpr(pos, text, leftChild: result, rightChild: try parseFactor())
        }
        return result
    }
    
    private func parseFactor() throws -> Expression {
        switch tokenizer.currentToken().type {
        case .MINUS, .PLUS:
            let operation = tokenizer.currentToken()
            try tokenizer.nextToken()
            return UnaryExpr(operation.position, operation.text, child: try parseFactor())
        case .ID:
            return try parseDescription()
        case .INT:
            let result = IntegerExpr(value: UInt64(tokenizer.currentToken().value)!, tokenizer.currentToken().position)
            result.type = SimpleType(tokenizer.currentToken().position, .INT)
            try tokenizer.nextToken()
            return result
        case .DOUBLE:
            let result = DoubleExpr(value: Double(tokenizer.currentToken().value)!, tokenizer.currentToken().position)
            result.type = SimpleType(tokenizer.currentToken().position, .DOUBLE)
            try tokenizer.nextToken()
            return result
        case .L_BRACKET:
            try tokenizer.nextToken()
            let result = try parseExpr()
            try require(.R_BRACKET)
            try tokenizer.nextToken()
            return result
        default:
            throw ParseErrors.unexpectedSymbol(tokenizer.currentToken().position, tokenizer.currentToken().text)
        }
    }
    
    private func parseDescription() throws -> Expression {
        try require(.ID)
        let name = tokenizer.currentToken().text
        let pos = tokenizer.currentToken().position
        try tokenizer.nextToken()
        if(tokenizer.currentToken().type == .L_BRACKET) {
            let funcCall = try parseCall(pos, name, true)
            let result = FuncDesignator(pos,name, (funcCall as! ProcFuncCall).paramList)
            result.type = try getIDType(name: name, pos)
            return result
        } else  {
            let result = IDExpr(name, pos)
            result.type = try getIDType(name: name, pos)
            return result
        }
    }
    
    // MARK: Test functions
    
    private var testDecl:DeclarationScope?
    private var testBlock:StatementNode?
    private var testExpr = false
    
    public func testExpressions() throws -> String {
        testExpr = true
        return drawExprTree(try parseExpr())
    }
    
    public func testExprTypes() throws -> String {
        return (try parseExpr().type?.text)!
    }
    
    public func testProgram() throws -> String {
        return drawBlockTree(try parseProgram("Main block"))
    }
    
    public func testStmt() throws -> String {
        return drawDeclTree(try parseDeclaration())
    }
    
    // MARK: Semantic
    
    func getIDType(name: String,_ pos: (Int, Int)) throws -> TypeNode? {
        if (testExpr) {
            return SimpleType(pos, .INT)
        }
        
        let variable = try check(name: name, pos)
        
        if (variable is VarDecl) {
            return (variable as! VarDecl).type
        } else if (variable is ProcFuncDecl)  {
            return (variable as! ProcFuncDecl).returnType!
        } else {
            return (variable as! ConstDecl).value.type!
        }
    }
    
    func check(name: String,_ pos: (Int, Int)) throws -> Declaration {
        if (varStack.isEmpty) {
            throw ParseErrors.unknownIdentifier(pos, name)
        }
        for i in 0..<varStack.count {
            if (varStack[varStack.count - 1 - i].declList.index(forKey: name) != nil) {
                return varStack[varStack.count - 1 - i].declList[name]!
            }
        }
        throw ParseErrors.unknownIdentifier(pos, name)
    }
    
    func require(_ token: TokenType) throws {
        if(token != tokenizer.currentToken().type) {
            throw ParseErrors.unexpectedSymbolBefore(tokenizer.currentToken().position, token.rawValue, tokenizer.currentToken().text)
        }
    }
    
    func require(_ tokens: [TokenType]) throws {
        var result = ""
        for token in tokens { result += token.rawValue + " or " }
        result = result[0..<result.length - 4]
        if (tokens.index(of: tokenizer.currentToken().type) == nil) {
            throw ParseErrors.unexpectedSymbolBefore(tokenizer.currentToken().position, result, tokenizer.currentToken().text)
        }
    }
    
    func checkCall(Of call:ProcFuncCall) throws {
        let proc = try check(name: call.name, call.position)
        if (proc.declType != .PROCEDURE) {
            throw ParseErrors.unknownSymbol(call.position, call.name)
        }
        if ((proc as! ProcFuncDecl).params.count != call.paramList.count) {
            throw ParseErrors.other("\(call.position) - different number of argument in \(call.name)")
        }
    
        for i in 0..<(proc as! ProcFuncDecl).params.count {
            let key = Array((proc as! ProcFuncDecl).params.keys)[i]
            let variable = (proc as! ProcFuncDecl).params[key]
            
            if ((variable as! VarDecl).type is SimpleType) {
                if !(call.paramList[i].type is SimpleType) {
                    throw ParseErrors.other("\(call.position) - expected simple type in \(call) arguments")
                } else {
                    try requireType(call.paramList[i].type!, (variable as! VarDecl).type, call.position)
                }
            } else {
                if ((variable as! VarDecl).type.nodeKind != call.paramList[i].type?.nodeKind) {
                    throw ParseErrors.unexpectedType(call.position, (call.paramList[i].type?.text)!)
                }
            }
        }
    }
    
}

func resultType(with oper1: Expression, and oper2: Expression, position: (Int, Int),_ text: String) throws -> TypeNode? {
    
    if !(oper1.type is SimpleType){
        throw ParseErrors.unexpectedType(position, (oper1.type?.text)!)
    }
    if !(oper2.type is SimpleType) {
        throw ParseErrors.unexpectedType(position, (oper2.type?.text)!)
    }
    
    let index1 = (oper1.type as! SimpleType).kind.rawValue + (oper2.type as! SimpleType).kind.rawValue
    let index2 = (oper2.type as! SimpleType).kind.rawValue + (oper1.type as! SimpleType).kind.rawValue
    
    let typeTable:[String: TypeNode] = [
        SimpleType.Kind.DOUBLE.rawValue + SimpleType.Kind.DOUBLE.rawValue: SimpleType(position, .DOUBLE),
        SimpleType.Kind.INT.rawValue + SimpleType.Kind.DOUBLE.rawValue: SimpleType(position, .DOUBLE),
        SimpleType.Kind.INT.rawValue + SimpleType.Kind.INT.rawValue: SimpleType(position, .INT)
    ]
    
    if (typeTable.index(forKey: index1) != nil) {
        return typeTable[index1]!
    } else if (typeTable.index(forKey: index2) != nil) {
        return typeTable[index2]!
    } else {
        throw ParseErrors.other("\(position) - operator \(text) have't overload for \((oper1.type?.text)!) and \((oper2.type?.text)!)")
    }
}

func possibleTypes(ofType type: TypeNode,_ position:(Int, Int)) throws -> [SimpleType.Kind] {
    if !(type is SimpleType) {
        throw ParseErrors.other("\(position) - expected simple type")
    }
    
    if((type as! SimpleType).kind == .INT) {
        return [.INT]
    }
    if((type as! SimpleType).kind == .DOUBLE) {
        return [.INT, .DOUBLE]
    }
    
    throw ParseErrors.unexpectedType(position, type.text)
}

func requireType(_ type: TypeNode,_ expectedType: TypeNode,_ position: (Int, Int)) throws {
    if !(type is SimpleType) {
        throw ParseErrors.other("\(position) - expected simple type")
    }
    
    if (try possibleTypes(ofType: expectedType, position).index(of: (type as! SimpleType).kind) == nil) {
         throw ParseErrors.other("\(position) - expected \((expectedType as! SimpleType).kind.rawValue) not \((type as! SimpleType).kind.rawValue)")
    }
}


