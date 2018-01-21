//
//  Node.swift
//  AGPC
//
//  Created by Andrey Gurev on 22.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

private func convertType(_ initType: TypeNode?) -> LLVarType {
    if(initType == nil) { return .VOID }
    var result:LLVarType
    switch (initType as! SimpleType).kind {
    case .DOUBLE:
        result = .DOUBLE
    case .INT:
        result = .I32
    default:
        result = .UN
    }
    
    return result
}

class StatementNode {
    enum Kind {
        case IFELSE, FOR, WHILE, BLOCK, ASSIGN, REPEAT, CALL, TRANSITION
    }
    var text: String
    var kind: Kind
    var position:(col: Int, row: Int)
    
    init(_ position: (Int, Int),_ kind: Kind,_ text: String) {
        self.text = text
        self.position = position
        self.kind = kind
    }
    
    func generate() -> [Llvm] {
        return []
    }
}

class ProcFuncCall: StatementNode {
    var paramList = [Expression]()
    var name: String
    init(_ position: (Int, Int),_ name:String,_ paramList:[Expression] = []) {
        self.paramList = paramList
        self.name = name
        super.init(position, .CALL, "Procedure or Function Call")
    }
    
    override func generate() -> [Llvm] {
        var LLparamList:[(LLVarType, String)] = []
        var resultArr:[Llvm] = []
        for param in self.paramList {
            resultArr.append(contentsOf: param.generate())
            LLparamList.append((convertType(param.type), param.text))
        }
        
        resultArr.append(LLCall(LLparamList, name, llvmVarStack[name]!.type))
        return resultArr
    }
}

class WritelnCall: ProcFuncCall {
    var ptrDeclare: String = ""
    
    override func generate() -> [Llvm] {
        var format: [String] = []
        var resultArr: [Llvm] = []
        var params: [(LLVarType, String)] = []
        if(paramList.isEmpty) { return [] }
        
        for param in paramList {
            format.append(((param.llvmVariable!.type.rawValue == "double") ? "%lf" : "%d") + " ")
            resultArr.append(contentsOf: param.generate())
            params.append((param.llvmVariable!.type, param.llvmVariable!.name))
        }
        
        resultArr.append(LLWriteln(format, params, self.position.col))
        return resultArr
    }
}

class ExitCall: ProcFuncCall {
    var ptrDeclare: String = ""
    
    override func generate() -> [Llvm] {
        var format: [String] = []
        var resultArr: [Llvm] = []
        var params: [(LLVarType, String)] = []
        if(paramList.isEmpty) { return [] }
        
        for param in paramList {
            format.append(((param.llvmVariable!.type.rawValue == "double") ? "%lf" : "%d") + " ")
            resultArr.append(contentsOf: param.generate())
            params.append((param.llvmVariable!.type, param.llvmVariable!.name))
        }
        
        resultArr.append(LLWriteln(format, params, self.position.col))
        return resultArr
    }
}

class TypeNode {
    enum NodeKind {
        case SIMPLE, ARRAY, RECORD
    }
    var position:(col: Int, row: Int)
    var nodeKind:NodeKind
    var text: String
    init(_ position: (Int, Int), _ nodeKind: NodeKind,_ text:  String) {
        self.position = position
        self.nodeKind = nodeKind
        self.text = text
    }
}

class SimpleType: TypeNode {
    enum Kind: String {
        case INT = "Integer", DOUBLE = "Double", ID = "ID"
    }
    var kind: Kind
    init(_ position: (Int, Int), _ kind: Kind) {
        self.kind = kind
        super.init(position, .SIMPLE, self.kind.rawValue)
    }
}

class ArrayType: TypeNode {
    var type:TypeNode
    var startIndex: Expression
    var finishIndex: Expression
    init(_ position: (Int, Int),_ type: TypeNode,_ startIndex: Expression,_ finishIndex: Expression) {
        self.type = type
        self.startIndex = startIndex
        self.finishIndex = finishIndex
        super.init(position, .ARRAY, "Array")
    }
}

class RecordType: TypeNode {
    var idList = [String: TypeNode]()
    init(_ position: (Int, Int)) {
        super.init(position, .RECORD, "Record")
    }
}

class Declaration {
    enum DeclType: String {
        case
        VAR = "Var", TYPE = "Type",
        CONST = "Const", PROCEDURE = "Procedure"
    }
    
    var declType: DeclType
    var text: String
    var position:(col: Int, row: Int)
    init(_ position: (Int, Int),_ text: String,_ declType:DeclType) {
        self.declType = declType
        self.text = text
        self.position = position
    }
    
    func generate() -> [Llvm] {
        return []
    }
}

class VarDecl: Declaration {
    var type: TypeNode
    init(_ position: (Int, Int), _ text: String,_ type: TypeNode) {
        self.type = type
        super.init(position, text, .VAR)
        llvmVarStack.updateValue(LlvmVariable(text, getLLVMType()), forKey: text)
    }
    override func generate() -> [Llvm] {
        let alloc = LLAlloc(text, llvmVarStack[text]!.type)
        let store = LLStore("\(llvmVarStack[text]!.type == .I32 ? "0" : "0.0")", llvmVarStack[text]!.type, text)
        return [alloc, store]
    }
    
    private func getLLVMType() -> LLVarType {
        if let _type = (self.type as? SimpleType) {
            switch (_type.kind) {
            case .DOUBLE: return .DOUBLE
            default:
                return .I32
            }
        } else {
            return .UN
        }
    }
}

class ProcFuncDecl: Declaration {
    var params = [String: Declaration]()
    var isForward: Bool
    var returnType: TypeNode? = nil
    var block:StatementNode
    var procName: String
    init(_ position: (Int, Int),_ procName: String, _ text: String,_ block: StatementNode,_ params: [String: Declaration] = [:],_ returnType: TypeNode? = nil,_ isForward:Bool = false){
        self.procName = procName
        self.block = block
        self.returnType = returnType
        self.params = params
        self.isForward = isForward
        
        llvmVarStack.updateValue(LlvmVariable(procName, convertType(self.returnType)), forKey: procName)
        
        super.init(position, text, .PROCEDURE)
    }
    
    override func generate() -> [Llvm] {
        var LLparamList:[(LLVarType, String)] = []
        var resultArr:[Llvm] = []
        for param in self.params {
            LLparamList.append(((convertType(((param.value as! VarDecl).type as! SimpleType)), param.key)))
        }
        
        resultArr.append(LLFunc(convertType(returnType), procName, LLparamList))
//
        if !((block as! Block).declScope == nil) {
            for (_, value) in ((block as! Block).declScope?.declList)! {
                resultArr.append(contentsOf: value.generate())
            }
        }
        
        resultArr.append(contentsOf: self.block.generate())
        resultArr.append(LLFuncEnd(convertType(returnType)))
    
        return resultArr
    }
}

class TypeDecl: Declaration {
    var type: TypeNode
    init(_ position: (Int, Int), _ text: String,_ type: TypeNode) {
        self.type = type
        super.init(position, text, .TYPE)
    }
}

class ConstDecl: Declaration {
    let value: Expression
    init(_ position: (Int, Int), _ text: String,_ value: Expression) {
        self.value = value
        super.init(position, text, .CONST)
    }
}

class DeclarationScope {
    var declList = [String: Declaration]()
}

class Block: StatementNode {
    var declScope: DeclarationScope?
    var stmtList = [StatementNode]()
    init(_ position: (Int, Int),_ text: String,_ declaration:DeclarationScope? = nil,_ stmtList:[StatementNode] = []) {
        self.declScope = declaration
        self.stmtList = stmtList
        super.init(position, .BLOCK, text)
    }
    
    override func generate() -> [Llvm] {
        var resultApp:[Llvm] = []
        for stmt in self.stmtList {
            resultApp.append(contentsOf: stmt.generate())
        }
        return resultApp
    }
}

class Transition: StatementNode {
    enum TransKind: String {
        case BREAK = "Break", CONTINUE = "Continue"
    }
    
    var tkind: TransKind;
    init(_ position: (Int, Int),_ tkind: TransKind) {
        self.tkind = tkind
        super.init(position, .TRANSITION, self.tkind.rawValue)
    }
    
    override func generate() -> [Llvm] {
        return [LLTransition(kind: (self.tkind == .BREAK) ? .BREAK : .CONTINUE)]
    }
}

class ForStmt: StatementNode {
    var startValue: StatementNode
    var finishValue: Expression
    var block: StatementNode
    init(_ position: (Int, Int),_ startValue:StatementNode,_ finishValue:Expression,_ block: StatementNode) {
        self.startValue = startValue
        self.block = block
        self.finishValue = finishValue
        super.init(position, .FOR, "For satement")
    }
    
    override func generate() -> [Llvm] {
        let initJump = LLLabel()
        var resulrArr:[Llvm] = [LLBr(initJump), initJump]
        resulrArr.append(contentsOf: startValue.generate())
        
        
        resulrArr.append(LLLoad("%iniIndex\(self.position.col)", .I32, .I32, "\((startValue as! AssignStmt).id)"))
        resulrArr.append(LLExpression(.SUB, .I32, "%iniIndex\(self.position.col)", "1", "%iresult\(self.position.col)"))
        resulrArr.append(LLStore("%iresult\(self.position.col)", .I32, "\((startValue as! AssignStmt).id)"))
        
        
        let comditionJump = LLLabel()
        resulrArr.append(LLBr(comditionJump))
        
        

        var conditionArr:[Llvm] = [comditionJump, LLLoad("%index\(self.position.col)", .I32, .I32, "\((startValue as! AssignStmt).id)")]
        conditionArr.append(contentsOf: finishValue.generate())
        
        conditionArr.append(LLExpression(.ADD, .I32, "%index\(self.position.col)", "1", "%result\(self.position.col)"))
        conditionArr.append(LLStore("%result\(self.position.col)", .I32, "\((startValue as! AssignStmt).id)"))
        
        conditionArr.append(LLExpression(.NE, .I32, "%index\(self.position.col)", "\(finishValue.llvmVariable!.name)", "%s\(self.position.col)-\(self.position.row)"))
        let jumpBlock = LLLabel()
        
        var blockArr:[Llvm] = [jumpBlock]
        blockArr.append(contentsOf: self.block.generate())
        blockArr.append(LLBr(comditionJump))
        
        let exitJump = LLLabel()

        blockArr.append(exitJump)
        conditionArr.append(LLBr("%s\(self.position.col)-\(self.position.row)", jumpBlock, exitJump))
        
        resulrArr.append(contentsOf: conditionArr)
        resulrArr.append(contentsOf: blockArr)
        
        createBreak(&resulrArr, exitJump, comditionJump)
        
        return resulrArr
    }
}

class WhileStmt: StatementNode {
    var condition: Expression
    var block: StatementNode
    init(_ position: (Int, Int),_ condition: Expression,_ block: StatementNode) {
        self.condition = condition
        self.block = block
        super.init(position, .WHILE, "While satement")
    }
    
    override func generate() -> [Llvm] {

        let conditionJump = LLLabel()
        var resulrArr:[Llvm] = [LLBr(conditionJump), conditionJump]
        resulrArr.append(contentsOf: self.condition.generate())

        let blockJump = LLLabel()
        var blockArr:[Llvm] = [blockJump]
        blockArr.append(contentsOf: self.block.generate())
        let exitJump = LLLabel()
        
        blockArr.append(contentsOf: [LLBr(conditionJump), exitJump])
        
        resulrArr.append(LLBr((condition.llvmVariable!.name), blockJump, exitJump))
        resulrArr.append(contentsOf: blockArr)
        
        createBreak(&resulrArr, exitJump, conditionJump)
    
        return resulrArr
    }
}

class RepeatStmt: StatementNode {
    var condition: Expression
    var block: StatementNode
    init(_ position: (Int, Int),_ condition: Expression,_ block: StatementNode) {
        self.condition = condition
        self.block = block
        super.init(position, .REPEAT, "Repeat satement")
    }
    
    override func generate() -> [Llvm] {
        let blockJump = LLLabel()
        var resultArr:[Llvm] = [LLBr(blockJump ), blockJump]
        resultArr.append(contentsOf: self.block.generate())
        
        let conditionJump = LLLabel()
        resultArr.append(LLBr(conditionJump))
        resultArr.append(conditionJump)
        resultArr.append(contentsOf: self.condition.generate())
        let exitJump = LLLabel()
        resultArr.append(LLBr((condition.llvmVariable!.name), blockJump, exitJump))
        
        resultArr.append(exitJump)
        
        createBreak(&resultArr, exitJump, conditionJump)
        
 
        return resultArr
    }
}

class IfElseStmt: StatementNode {
    var condition: Expression
    var block: StatementNode
    var elseBlock: StatementNode?
    init(_ position: (Int, Int),_ cond: Expression,_ block: StatementNode,_ elseBlock:StatementNode? = nil) {
        self.condition = cond
        self.block = block
        self.elseBlock = elseBlock
        super.init(position, .IFELSE, "If-Else statement")
    }
    
    override func generate() -> [Llvm] {
        var resultArr:[Llvm] = []
        resultArr.append(contentsOf: condition.generate())
        let jumpIf = LLLabel()
        
        var blockArr:[Llvm] = [jumpIf]
        blockArr.append(contentsOf: block.generate())
        
        let jumpElse = LLLabel()
        resultArr.append(LLBr(condition.llvmVariable!.name, jumpIf, jumpElse))
        resultArr.append(contentsOf: blockArr)
        
        if(elseBlock != nil) {
            var elseArr:[Llvm] = []
            elseArr.append(jumpElse)
            elseArr.append(contentsOf: elseBlock!.generate())
            
            let jumpExit = LLLabel()
            elseArr.append(contentsOf: [LLBr(jumpExit), jumpExit])
            
            resultArr.append(LLBr(jumpExit))
            resultArr.append(contentsOf: elseArr)

        } else {
            resultArr.append(contentsOf: [LLBr(jumpElse), jumpElse])
        }
        
        return resultArr
    }
}

class AssignStmt: StatementNode {
    var id: String
    var expr: Expression
    init(_ position: (Int, Int),_ expr: Expression,_ id: String) {
        self.id = id
        self.expr = expr
        super.init(position, .ASSIGN, "Assign")
    }
    
    override func generate() -> [Llvm] {
        var resultArr:[Llvm] = []
        resultArr.append(contentsOf: expr.generate())
        var storeValue = expr.llvmVariable!.name
        if (expr.kind != .INT && expr.kind != .DOUBLE) {
            if(expr.llvmVariable!.type != llvmVarStack[id]!.type) {
                resultArr.append(LLCast(expr.llvmVariable!.name, expr.llvmVariable!.type, llvmVarStack[id]!.type))
                storeValue = "\(expr.llvmVariable!.name)cast"
            } else {
                storeValue = "\(expr.llvmVariable!.name)"
            }
        } else {
            if(expr.kind == .INT && llvmVarStack[id]!.type == .DOUBLE) {
                storeValue = expr.llvmVariable!.name + ".0"
            }
        }
        
        resultArr.append(LLStore(storeValue, llvmVarStack[id]!.type, id))
        return resultArr
    }
}

class Expression {
    enum Kind {
        case UNARY, BINARY, INT, DOUBLE, ID, FUNCTION
    }
    
    var type: TypeNode? = nil
    var text: String
    var llvmVariable: LlvmVariable?
    var kind: Kind
    var position:(col: Int, row: Int)
    
    init(_ position: (Int, Int),_ kind: Kind,_ text: String) {
        self.text = text
        self.position = position
        
        self.kind = kind
    }
    
    func generate() -> [Llvm] {
        return []
    }
}

class BinaryExpr: Expression {
    let leftChild: Expression
    let rightChild: Expression
    
    private func getType() throws {
        if (self.text == "/") {
            super.type = SimpleType(self.position, .DOUBLE)
        } else {
            super.type = try resultType(with: leftChild, and: rightChild, position: position, self.text)
        }
    }
    
    override func generate() -> [Llvm] {
        var oper: LLExpression.Oper
        let _type = (self.type! as! SimpleType).kind
        switch (self.text) {
        case "-":
            oper = (_type == .DOUBLE) ? .FSUB : .SUB
        case "*":
            oper = (_type == .DOUBLE) ? .FMUL : .MUL
        case "/":
            oper = .FDIV
        case "mod":
            oper = .SREM
        case "div":
            oper = .DIV
        case "and":
            oper = .AND
        case "or":
            oper = .OR
        case "=":
            oper = (_type == .DOUBLE) ? .FOEQ : .EQ
        case "<>":
            oper = (_type == .DOUBLE) ? .FONE : .NE
        case ">":
            oper = (_type == .DOUBLE) ? .FOGT : .SGT
        case ">=":
            oper = (_type == .DOUBLE) ? .FOGE : .SGE
        case "<":
            oper = (_type == .DOUBLE) ? .FOLT : .SLT
        case "<=":
            oper = (_type == .DOUBLE) ? .FOLE : .SLE
        default:
            oper = (_type == .DOUBLE) ? .FADD : .ADD
        }
        
        var right = self.rightChild.llvmVariable!.name
        var left = self.leftChild.llvmVariable!.name
        var cast:LLCast?

        var resultArr:[Llvm] = []
        
        if(_type == .DOUBLE) {
            if(self.rightChild.kind == .INT) {
                right += ".0"
            } else if(self.rightChild.llvmVariable!.type == .I32) {
                cast = LLCast(right, .I32, .DOUBLE)
                right = cast!.name
            }
            
            if(self.leftChild.kind == .INT) {
                left += ".0"
            } else if(self.leftChild.llvmVariable!.type == .I32) {
                cast = LLCast(left, .I32, .DOUBLE)
                left = cast!.name
            }
        }
        
        resultArr.append(contentsOf: self.leftChild.generate())
        resultArr.append(contentsOf: self.rightChild.generate())
        if (cast != nil) {
            resultArr.append(cast!)
        }
        resultArr.append(LLExpression(oper, getLLVMType(), left, right, llvmVariable!.name))
        
        return resultArr
    }
    
    private func getLLVMType() -> LLVarType {
        if let _type = (self.type as? SimpleType) {
            switch (_type.kind) {
            case .DOUBLE: return .DOUBLE
            default:
                return .I32
            }
        } else {
            return .UN
        }
    }
    
    init(_ position: (Int, Int),_ text: String, leftChild: Expression, rightChild: Expression) throws {
        self.leftChild = leftChild
        self.rightChild = rightChild
        super.init(position, .BINARY, text)
        try getType()
        self.llvmVariable = LlvmVariable("%s\(position.0)-\(position.1)", getLLVMType())
        llvmVarStack.updateValue(LlvmVariable(llvmVariable!.name, getLLVMType()), forKey: llvmVariable!.name)
    }
}

class UnaryExpr: Expression {
    let child: Expression
    
    private func getType() {
        super.type = child.type
    }
    
    override func generate() -> [Llvm] {
        var resultArr: [Llvm] = []
        if(self.text == "+") {
            return []
        }
        
        resultArr.append(LLExpression(((child.llvmVariable?.type == .I32) ? .SUB : .FSUB), (child.llvmVariable?.type)!, ((child.llvmVariable?.type == .I32) ? "0" : "0.0"), child.llvmVariable!.name, self.llvmVariable!.name))
        return resultArr
    }
    
    init(_ position: (Int, Int),_ text: String, child: Expression) {
        self.child = child
        super.init(position, .UNARY, text)
        getType()
        if !(testExpr) {
            self.llvmVariable = (self.text == "+") ? child.llvmVariable : LlvmVariable("%s\(position.0)-\(position.1)", child.llvmVariable!.type)
        }
    }
}

class IDExpr: Expression {
    var name: String
    init(_ name: String,_ position: (Int, Int)) {
        self.name = name
        super.init(position, .ID, self.name)
        if !(testExpr) {
            self.llvmVariable = LlvmVariable("%s\(position.0)-\(position.1)", llvmVarStack[name]!.type)
        }
    }
    
    override func generate() -> [Llvm] {
        return [LLLoad(llvmVariable!.name, llvmVarStack[name]!.type, llvmVarStack[name]!.type, name)]
    }
}

class IntegerExpr: Expression {
    var value: UInt64
    init(value: UInt64,_ position: (Int, Int)) {
        self.value = value
        super.init(position, .INT, String(self.value))
        self.llvmVariable = LlvmVariable(String(value), .I32)
    }
}

class DoubleExpr: Expression {
    var value: Double
    init(value: Double,_ position: (Int, Int)) {
        self.value = value
        super.init(position, .DOUBLE, String(self.value))
        self.llvmVariable = LlvmVariable(String(value), .DOUBLE)
    }
}

class FuncDesignator: Expression {
    var name: String
    var paramList = [Expression]()
    init(_ position: (Int, Int),_ name: String,_ paramList:[Expression] = []) {
        self.name = name
        self.paramList = paramList
        super.init(position, .FUNCTION, self.name)
    }
}
