//
//  Painter.swift
//  AGPC
//
//  Created by Andrey Gurev on 30.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

func lexemTable(_ lexems: [Token]) ->  String {
    let column1PadLength = 20
    let columnDefaultPadLength = 20
    
    var errors = ""
    for error in errorMessages {
        errors += error + "\n"
    }
    
    let headerString = "Position".padding(toLength: column1PadLength, withPad: " ", startingAt: 0) + "Type".padding(toLength: column1PadLength + 5, withPad: " ", startingAt: 0) +
        "Text".padding(toLength: columnDefaultPadLength, withPad: " ", startingAt: 0) +
        "Value".padding(toLength: columnDefaultPadLength, withPad: " ", startingAt: 0)
    
    let lineString = "".padding(toLength: headerString.characters.count, withPad: "-", startingAt: 0)
    
    var dataString = ""
    for lexem in lexems {
        let number = "(\(lexem.position.row),\(lexem.position.col))"
        dataString += number.padding(toLength: column1PadLength, withPad: " ", startingAt: 0) + lexem.type.rawValue.padding(toLength: columnDefaultPadLength + 5, withPad: " ", startingAt: 0) + lexem.text.padding(toLength: columnDefaultPadLength, withPad: " ", startingAt: 0) +
            lexem.value.padding(toLength: columnDefaultPadLength, withPad: " ", startingAt: 0)
        dataString.append("\n")
    }
    return "\(errors)\(headerString)\n\(lineString)\n\(dataString)"
}

func drawBlockTree(_ stmtNode: StatementNode? = nil,_ tabNumber: Int = 0) -> String {
    if(stmtNode == nil) { return "" }
    var tabstr = ""
    
    var result: String = ""
    if (stmtNode is Block) {
        if ((stmtNode as! Block).declScope != nil) {
            result = drawDeclTree((stmtNode as! Block).declScope, tabNumber) + "\n"
        }
    }
    
    (tabNumber > 0) ? (tabstr = String(repeating: " ", count: tabNumber - 1)) : (result += stmtNode!.text + "\n")
    
    if (stmtNode is Block) {
        result += drawStmtTree((stmtNode as! Block).stmtList, (tabNumber == 0) ? tabNumber + 1 : tabNumber)
    } else {
        result += drawStmtTree([stmtNode!], (tabNumber == 0) ? tabNumber + 1 : tabNumber)
    }
    return ((tabNumber != 0) ? result : result + "End of \(stmtNode!.text)\n")
}

func drawStmtTree(_ stmtList: [StatementNode],_ tabNumber: Int = 0) -> String {
    var result = ""
    let tabstr = String(repeating: " ", count: tabNumber)
    
    let exprTree = {(expr: Expression) -> String in
        var tree = drawExprTree(expr, tabNumber + 1)
        tree.removeFirst()
        return "\(tabstr) ⎬\(tree)\n"
    }
    
    for stmt in stmtList {
        var titleTabs = tabstr
        if (tabNumber > 0) { titleTabs.removeFirst() }
        result += "\(titleTabs) ⎬ \(stmt.text)\n"
        switch stmt {
        case is AssignStmt:
            let assignStmt = (stmt as! AssignStmt)
            result += "\(tabstr) ⎬\(assignStmt.id)\n"
            result += exprTree(assignStmt.expr)
        case is IfElseStmt:
            let IfElseStmt = (stmt as! IfElseStmt)
            result += exprTree(IfElseStmt.condition)
            result += "\(drawBlockTree(IfElseStmt.block, tabNumber + 1))"
            if(IfElseStmt.elseBlock != nil) {
                result += "\(tabstr)⎬ Else\n"
                result += "\(drawBlockTree(IfElseStmt.elseBlock, tabNumber + 1))"
            }
        case is ForStmt:
            let forStmt = (stmt as! ForStmt)
            result += "\(tabstr) ⎬\((forStmt.startValue as! AssignStmt).id)\n"
            result += exprTree((forStmt.startValue as! AssignStmt).expr)
            result += exprTree(forStmt.finishValue)
            result += "\(drawBlockTree(forStmt.block, tabNumber + 1))"
        case is WhileStmt:
            let whileStmt = (stmt as! WhileStmt)
            result += exprTree(whileStmt.condition)
            result += "\(drawBlockTree(whileStmt.block, tabNumber + 1))"
        case is RepeatStmt:
            let repeatStmt = (stmt as! RepeatStmt)
            result += exprTree(repeatStmt.condition)
            result += "\(drawBlockTree(repeatStmt.block, tabNumber + 1))"
        default:
            result += "WTF?"
        }
    }
    return result
}

func drawDeclTree(_ declScope: DeclarationScope? = nil,_ tabNumber: Int = 0) -> String {
    if(declScope == nil) { return "" }
    
    let tabstr = String(repeating: " ", count: tabNumber)
    var result = "\(tabstr)Declaration"
    
    for (key,value) in declScope!.declList {
        if value is VarDecl {
            result += "\n\(tabstr) ⎬\(key) - \((value as! VarDecl).type.type.rawValue)(\(value.declType.rawValue))"
        } else {
            var exprTree = drawExprTree((value as! ConstDecl).value, key.length + 4)
            exprTree.removeFirst()
            result += "\n\(tabstr) ⎬\(key) - \(exprTree)(\(value.declType.rawValue))"
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
