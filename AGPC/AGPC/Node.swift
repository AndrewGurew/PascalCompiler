//
//  Node.swift
//  AGPC
//
//  Created by Andrey Gurev on 22.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//

import Foundation

class StatementNode {
    enum Kind {
        case IFELSE, FOR, WHILE, BLOCK
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

class IdentType {
    var position:(col: Int, row: Int)
    var type:TokenEnum
    init(_ position: (Int, Int), _ type:TokenEnum) {
        self.position = position
        self.type = type
    }
}


class Declaration {
    enum DeclType: String {
        case VAR = "Var", TYPE = "Type",
        CONST = "Const"
    }
    
    var declType: DeclType
    var type: IdentType
    var text: String
    var position:(col: Int, row: Int)
    init(_ position: (Int, Int),_ text: String,_ declType:DeclType,_ type: IdentType) {
        self.declType = declType
        self.text = text
        self.type = type
        self.position = position
    }
}

class VarType: Declaration {
    init(_ position: (Int, Int), _ text: String,_ type: IdentType) {
        super.init(position, text, .VAR, type)
    }
}

class DeclarationScope {
    var declList = [String: Declaration]()
}

class Block: StatementNode {
    var declScope: DeclarationScope?
    var stmtList = [StatementNode]()
    init(_ position: (Int, Int),_ text: String,_ declaration:DeclarationScope? = nil) {
        self.declScope = declaration
        super.init(position, .BLOCK, text)
    }
}

class IfElseStmt: StatementNode {
    var condition: Expression
    var block: StatementNode
    var elseBlock: StatementNode?
    init(_ position: (Int, Int),_ text: String,_ cond: Expression,_ block: StatementNode,_ elseBlock:StatementNode? = nil) {
        self.condition = cond
        self.block = block
        self.elseBlock = elseBlock
        super.init(position, .IFELSE, text)
    }
}

class Expression {
    enum Kind {
        case UNARY, BINARY, INT, DOUBLE, ID
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

class BinaryExpr: Expression {
    let leftChild: Expression
    let rightChild: Expression
    init(_ position: (Int, Int),_ text: String, leftChild: Expression, rightChild: Expression) {
        self.leftChild = leftChild
        self.rightChild = rightChild
        super.init(position, .BINARY, text)
    }
}

class UnaryExpr: Expression {
    let child: Expression
    init(_ position: (Int, Int),_ text: String, child: Expression) {
        self.child = child
        super.init(position, .UNARY, text)
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
