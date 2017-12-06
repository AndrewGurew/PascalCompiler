//
//  Node.swift
//  AGPC
//
//  Created by Andrey Gurev on 22.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

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
}

class VarDecl: Declaration {
    var type: TypeNode
    init(_ position: (Int, Int), _ text: String,_ type: TypeNode) {
        self.type = type
        super.init(position, text, .VAR)
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
}

class AssignStmt: StatementNode {
    var id: String
    var expr: Expression
    init(_ position: (Int, Int),_ expr: Expression,_ id: String) {
        self.id = id
        self.expr = expr
        super.init(position, .ASSIGN, "Assign")
    }
}

class Expression {
    enum Kind {
        case UNARY, BINARY, INT, DOUBLE, ID, FUNCTION
    }
    
    var type: TypeNode? = nil
    var text: String
    var kind: Kind
    var position:(col: Int, row: Int)
    
    init(_ position: (Int, Int),_ kind: Kind,_ text: String) {
        self.text = text
        self.position = position
        
        self.kind = kind
    }
}

class BinaryExpr: Expression {
    let leftChild: Expression
    let rightChild: Expression
    
    private func getType() {
        if (self.text == "/") {
            super.type = SimpleType(self.position, .DOUBLE)
        } else {
            super.type = resultType(with: leftChild, and: rightChild, position: position)
        }
    }
    
    init(_ position: (Int, Int),_ text: String, leftChild: Expression, rightChild: Expression) {
        self.leftChild = leftChild
        self.rightChild = rightChild
        super.init(position, .BINARY, text)
        getType()
    }
}

class UnaryExpr: Expression {
    let child: Expression
    
    private func getType() {
        super.type = child.type
    }
    
    init(_ position: (Int, Int),_ text: String, child: Expression) {
        self.child = child
        super.init(position, .UNARY, text)
        getType()
    }
}

class IDExpr: Expression {
    var name: String
    init(_ name: String,_ position: (Int, Int)) {
        self.name = name
        super.init(position, .ID, self.name)
    }
}

class IntegerExpr: Expression {
    var value: UInt64
    init(value: UInt64,_ position: (Int, Int)) {
        self.value = value
        super.init(position, .INT, String(self.value))
    }
}

class DoubleExpr: Expression {
    var value: Double
    init(value: Double,_ position: (Int, Int)) {
        self.value = value
        super.init(position, .DOUBLE, String(self.value))
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
