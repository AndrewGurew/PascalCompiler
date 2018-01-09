//
//  Node.swift
//  AGPC
//
//  Created by Andrey Gurev on 22.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

var _globalDeclare = ""
var labelIndex = 0
var writelnDeclared:[Int:Bool] = [:]
var printPointerDeclared = false

func initGenerator()  {
    _globalDeclare = ""
    labelIndex = 0
    writelnDeclared = [:]
    printPointerDeclared = false
}

class StatementNode {
    enum Kind {
        case IFELSE, FOR, WHILE, BLOCK, ASSIGN, REPEAT, CALL
    }
    var text: String
    var kind: Kind
    var position:(col: Int, row: Int)
    
    init(_ position: (Int, Int),_ kind: Kind,_ text: String) {
        self.text = text
        self.position = position
        self.kind = kind
    }
    
    func generate() -> String {
        return ""
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
}

class WritelnCall: ProcFuncCall {
    var ptrDeclare: String = ""
    
    override func generate() -> String {
        var format = ""
        var outputVariables = ""
        var codeByVariables = ""
        if(paramList.isEmpty) { return "" }
        
        for param in paramList {
            format += ((param.llvmVariable!.type == "double") ? "%lf" : "%d") + " "
            codeByVariables += param.generate()
            outputVariables += "\(param.llvmVariable!.type) \(param.llvmVariable!.name)" + ","
        }
        outputVariables.removeLast()
        
        if (writelnDeclared.index(forKey: paramList.count) == nil) || (writelnDeclared[paramList.count] == false) {
            _globalDeclare += "@hello\(paramList.count) = private constant [\(format.length) x i8] c\"\(format)\"\n";
            writelnDeclared[paramList.count] = true
        }
        
        ptrDeclare = "%ptr\(self.position.col) = bitcast [\(format.length) x i8] * @hello\(paramList.count) to i8*\n"
        labelIndex+=1
        
        
        let command = ptrDeclare + "call i32 (i8*, ...) @printf(i8* %ptr\(self.position.col), \(outputVariables))\n"
        return codeByVariables + command
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
    
    func generate() -> String {
        return ""
    }
}

class VarDecl: Declaration {
    var type: TypeNode
    init(_ position: (Int, Int), _ text: String,_ type: TypeNode) {
        self.type = type
        super.init(position, text, .VAR)
        llvmVarStack.updateValue(LlvmVariable(text, getLLVMType()), forKey: text)
    }
    override func generate() -> String {
        let alloc = "%\(text) = alloca \(llvmVarStack[text]!.type), align 4\n"
        let store = "store \(llvmVarStack[text]!.type) \(llvmVarStack[text]!.type == "i32" ? "0" : "0.0"), \(llvmVarStack[text]!.type)* %\(text), align 4\n"
        return alloc + store
    }
    
    private func getLLVMType() -> String {
        if let _type = (self.type as? SimpleType) {
            switch (_type.kind) {
            case .DOUBLE: return "double"
            default:
                return "i32"
            }
        } else {
            return "UN"
        }
    }
}

class ProcFuncDecl: Declaration {
    var params = [String: Declaration]()
    var isForward: Bool
    var returnType: TypeNode? = nil
    var block:StatementNode
    init(_ position: (Int, Int), _ text: String,_ block: StatementNode,_ params: [String: Declaration] = [:],_ returnType: TypeNode? = nil,_ isForward:Bool = false){
        self.block = block
        self.returnType = returnType
        self.params = params
        self.isForward = isForward
        super.init(position, text, .PROCEDURE)
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
    
    override func generate() -> String {
        var result = ""
        for stmt in self.stmtList {
            result += stmt.generate()
        }
        return result
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
    
    override func generate() -> String {
        labelIndex+=1
        var initLabel = "br label %\(labelIndex)\n"
        initLabel += "; <label>:\(labelIndex)\n"
        initLabel += startValue.generate()
        labelIndex+=1
        initLabel += "br label %\(labelIndex)\n"
        
        
        
        let conditonIndex = labelIndex
        var condition = "; <label>:\(labelIndex)\n"
        condition += "%index\(self.position.col) = load i32, i32* %\((startValue as! AssignStmt).id), align 4\n"
        condition += finishValue.generate()
        condition += "%s\(self.position.col)-\(self.position.row) = icmp sle i32 %index\(self.position.col), \(finishValue.llvmVariable!.name)\n"
        condition += "br i1 %s\(self.position.col)-\(self.position.row), label %\(labelIndex + 1), "
        
        labelIndex+=1
        var blockLabel = "; <label>:\(labelIndex)\n"
        blockLabel += self.block.generate()
        blockLabel += "%result\(self.position.col) = add i32 %index\(self.position.col), 1\n"
        blockLabel += "store i32 %result\(self.position.col), i32* %\((startValue as! AssignStmt).id), align 4\n"
        
        blockLabel += "br label %\(conditonIndex)\n"
        labelIndex += 1
        blockLabel += "; <label>:\(labelIndex)\n"
        condition += "label %\(labelIndex)\n"
        
        return initLabel + condition + blockLabel
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
}

class RepeatStmt: StatementNode {
    var condition: Expression
    var block: StatementNode
    init(_ position: (Int, Int),_ condition: Expression,_ block: StatementNode) {
        self.condition = condition
        self.block = block
        super.init(position, .REPEAT, "Repeat satement")
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
    
    override func generate() -> String {
        labelIndex+=1
        var result = ""
        var elseBlockResult = ""
        var ifBlockResult = ""
        result += condition.generate()
        var br = "br i1 \(condition.llvmVariable!.name), label %\(labelIndex), "
        ifBlockResult += "; <label>:\(labelIndex)\n"
        ifBlockResult += block.generate()
        labelIndex+=1
        br += "label %\(labelIndex)\n"
        if(elseBlock != nil) {
            labelIndex+=1
            elseBlockResult = "; <label>:\(labelIndex - 1)\n"
            elseBlockResult += self.elseBlock!.generate()
            elseBlockResult += "br label %\(labelIndex)\n"
        }
        
        ifBlockResult += "br label %\(labelIndex)\n"
        return result + br + ifBlockResult + elseBlockResult + "; <label>:\(labelIndex)\n"
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
    
    override func generate() -> String {
        let expressonCode = expr.generate()
        var storeValue = ((expr.kind == .INT) ? "i32 " : "double ") + expr.llvmVariable!.name
        var cast = ""
        if (expr.kind != .INT && expr.kind != .DOUBLE) {
            if(expr.llvmVariable!.type != llvmVarStack[id]!.type) {
                cast = "\(expr.llvmVariable!.name)cast = sitofp \(expr.llvmVariable!.type) \(expr.llvmVariable!.name) to \(llvmVarStack[id]!.type)\n"
                storeValue = "\(llvmVarStack[id]!.type) \(expr.llvmVariable!.name)cast"
            } else {
                storeValue = "\(expr.llvmVariable!.type) \(expr.llvmVariable!.name)"
            }
        } else {
            if(expr.kind == .INT && llvmVarStack[id]!.type == "double") {
                storeValue = "double " + expr.llvmVariable!.name + ".0"
            }
        }
        let store = "store \(storeValue), \(llvmVarStack[id]!.type)* %\(id), align 4\n"
        return expressonCode + cast + store
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
    
    func generate() -> String {
        return ""
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
    
    override func generate() -> String {
        var oper = ""
        let _type = (self.type! as! SimpleType).kind
        switch (self.text) {
        case "-":
            oper = (_type == .DOUBLE) ? "fsub" : "sub"
        case "*":
            oper = (_type == .DOUBLE) ? "fsmul" : "mul"
        case "/":
            oper = "fdiv"
        case "mod":
            oper = "srem"
        case "div":
            oper = "sdiv"
        case "and", "or":
            oper = self.text
        case "=":
            oper = (_type == .DOUBLE) ? "fcmp oeq" : "icmp eq"
        case "<>":
            oper = (_type == .DOUBLE) ? "fcmp one" : "icmp ne"
        case ">":
            oper = (_type == .DOUBLE) ? "fcmp ogt" : "icmp sgt"
        case ">=":
            oper = (_type == .DOUBLE) ? "fcmp oge" : "icmp sge"
        case "<":
            oper = (_type == .DOUBLE) ? "fcmp olt" : "icmp slt"
        case "<=":
            oper = (_type == .DOUBLE) ? "fcmp ole" : "icmp sle"
        default:
            oper = (_type == .DOUBLE) ? "fadd" : "add"
        }
        
        var right = self.rightChild.llvmVariable!.name
        var left = self.leftChild.llvmVariable!.name
        var cast = ""
        
        if(_type == .DOUBLE) {
            if(self.rightChild.kind == .INT) {
                right += ".0"
            } else if(self.rightChild.llvmVariable!.type == "i32") {
                cast += "\(llvmVariable!.name)cast = sitofp i32 \(right) to double\n"
                right = "\(llvmVariable!.name)cast"
            }
            
            if(self.leftChild.kind == .INT) {
                left += ".0"
            } else if(self.leftChild.llvmVariable!.type == "i32") {
                cast += "\(llvmVariable!.name)cast = sitofp i32 \(left) to double\n"
                left = "\(llvmVariable!.name)cast"
            }
        }
        
        let command = self.leftChild.generate() + self.rightChild.generate() + cast + "\(llvmVariable!.name) = \(oper) \(getLLVMType()) \(left), \(right)\n"
        
        return command
    }
    
    private func getLLVMType() -> String {
        if let _type = (self.type as? SimpleType) {
            switch (_type.kind) {
            case .DOUBLE: return "double"
            default:
                return "i32"
            }
        } else {
            return "UN"
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
    
    override func generate() -> String {
        return (self.text == "+") ? "" : "\(self.llvmVariable!.name) = \((child.llvmVariable?.type == "i32") ? "sub nsw" : "fsub") \(child.llvmVariable!.type) \((child.llvmVariable?.type == "i32") ? "0" : "0.0"), \(child.llvmVariable!.name)\n"
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
    
    override func generate() -> String {
        return "\(llvmVariable!.name) = load \(llvmVarStack[name]!.type), \(llvmVarStack[name]!.type)* %\(name), align 4\n"
    }
}

class IntegerExpr: Expression {
    var value: UInt64
    init(value: UInt64,_ position: (Int, Int)) {
        self.value = value
        super.init(position, .INT, String(self.value))
        self.llvmVariable = LlvmVariable(String(value), "i32")
    }
}

class DoubleExpr: Expression {
    var value: Double
    init(value: Double,_ position: (Int, Int)) {
        self.value = value
        super.init(position, .DOUBLE, String(self.value))
        self.llvmVariable = LlvmVariable(String(value), "double")
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
