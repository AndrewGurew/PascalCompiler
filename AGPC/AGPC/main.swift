//
//  main.swift
//  AGPC
//
//  Created by Andrey Gurev on 06.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

func lexTabale(progText: String) throws -> String {
    let lexAnalyzer = Tokenizer(text: progText)
    return try lexAnalyzer.test();
}

func exTree(progText: String) throws -> String {
    let lexAnalyzer = Tokenizer(text: progText)
    let expressionParser = Parser(tokenizer: lexAnalyzer)
    return try expressionParser.testExpressions()
}

func exType(progText: String) throws -> String {
    let lexAnalyzer = Tokenizer(text: progText)
    let expressionParser = Parser(tokenizer: lexAnalyzer)
    return try expressionParser.testExprTypes()
}

func declTree(progText: String) throws -> String {
    let lexAnalyzer = Tokenizer(text: progText)
    let stmtParser = Parser(tokenizer: lexAnalyzer)
    return try stmtParser.testStmt()
}

func stmtTree(progText: String) throws -> String {
    let lexAnalyzer = Tokenizer(text: progText)
    let stmtParser = Parser(tokenizer: lexAnalyzer)
    return try stmtParser.testAllStmt()
}

enum Mod {
    case RELEASE
    case TEST
    case GEN_TEST_ANSWERS
    case HELP
}

typealias Method = (String) throws -> String

struct Test {
    var text: String
    var method: Method
    var testPath: String
    init(_ text: String,_ method: @escaping Method,_ testPath: String) {
        self.text = text
        self.method = method
        self.testPath = testPath
    }
}

let testParts:[Test] = [
    Test("Lexical tests:\n", lexTabale, "/Users/Andrey/Desktop/Swift/PascalCompiler/Tests/Lex"),
    Test("Expression tests:\n", exTree, "/Users/Andrey/Desktop/Swift/PascalCompiler/Tests/Expressions"),
    Test("Declaration tests:\n", declTree, "/Users/Andrey/Desktop/Swift/PascalCompiler/Tests/Declarations"),
    Test("Statement tests:\n", stmtTree, "/Users/Andrey/Desktop/Swift/PascalCompiler/Tests/Statements"),
    Test("Expression type tests:\n", exType, "/Users/Andrey/Desktop/Swift/PascalCompiler/Tests/ExprType")
]

var mod:Mod = .RELEASE
var keys = [String]()
var fileName:String?

func usualMod(progText: String) throws -> String {
    let LexAnalyzer = Tokenizer(text: progText)
    var result = ""
    
    if(keys.index(of: "-l") != nil) {
        result = try LexAnalyzer.test()
    }
    if(keys.index(of: "-e") != nil) {
        let ExpressionParser = Parser(tokenizer: LexAnalyzer)
        result = try ExpressionParser.testAllStmt()
    }
    
    return result
}

if(CommandLine.arguments.count <= 1) {
    print("Pascal compiler.\nCreated by Andrey Gurev on 2017.\nCopyright © 2017 Andrey Gurev. All rights reserved.")
} else {
    switch(CommandLine.arguments[1].lowercased()) {
    case "test":
         mod = .TEST
    case "gen":
        mod = .GEN_TEST_ANSWERS
    case "-h":
        mod = .HELP
    default:
        fileName = CommandLine.arguments[1]
        for i in 2..<CommandLine.arguments.count {
            keys.append(CommandLine.arguments[i].lowercased())
        }
    }
}

func getResult(_ method: Method,_ progText: String) -> String {
    do {
        return try method(progText)
    } catch ParseErrors.unknownSymbol(let pos, let text) {
        return unknownSymbolMessage(pos, text)
    } catch ParseErrors.unknownIdentifier(let pos, let text) {
        return unknownIdentifierMessage(pos, text)
    } catch ParseErrors.unexpectedSymbolBefore(let pos, let expected, let text) {
        return unexpectedSymbolBeforeMessage(pos, expected, text)
    } catch ParseErrors.duplicateDeclaration(let pos, let text) {
        return duplicateDeclarationMessage(pos, text)
    } catch ParseErrors.unexpectedSymbol(let pos, let text) {
        return unexpectedSymbolMessage(pos, text)
    } catch ParseErrors.other(let text) {
        return otherMessage(text)
    } catch {
        return unknownErrorMessage()
    }
}

func extractAllFile(atPath path: String, withExtension fileExtension:String) -> [String] {
    let pathURL = NSURL(fileURLWithPath: path, isDirectory: true)
    var allFiles: [String] = []
    let fileManager = FileManager.default
    if let enumerator = fileManager.enumerator(atPath: path) {
        for file in enumerator {
            if let path = NSURL(fileURLWithPath: file as! String, relativeTo: pathURL as URL).path, path.hasSuffix(".\(fileExtension)"){
                allFiles.append(path)
            }
        }
    }
    return allFiles
}

switch(mod){
case .HELP:
    print("Commands:")
    print("\ttest: tests the work of the compiler")
    print("Options:")
    print("\t-h: Show help banner of specified command")
    print("\t-l: Lexical code analysis")
    print("\t-e: Expression parse")
case .TEST:
    var testNumber = 0
    var failedTestsNumber = 0
    for testPart in testParts {
        print("\n\(testPart.text)")
        let allTextFiles = extractAllFile(atPath: testPart.testPath, withExtension: "pas")
        testNumber += allTextFiles.count
        for file in allTextFiles {
            errorMessages.removeAll()
            
            do {
                let progText = try String(contentsOf: NSURL.fileURL(withPath: file))
                let outPut = (file.replacingOccurrences(of: ".pas", with: ".out"))
                let ansText = try String(contentsOf: NSURL.fileURL(withPath: outPut))
            
                let result = getResult(testPart.method, progText)
                
                var testResult = "Test number \(allTextFiles.index(of: file)! + 1) - "
                if (result == ansText) {
                    testResult.append("OK")
                } else {
                    failedTestsNumber+=1
                    print(progText)
                    testResult.append("NO")
                }
                print(testResult)
            } catch {
                print("Error loading contents of:", file, error)
            }
        }
    }
    
    print("-----------------------\nTest count:\(testNumber)\nPassed: \(testNumber - failedTestsNumber) Failed: \(failedTestsNumber)\n")
case .GEN_TEST_ANSWERS:
    for testPart in testParts {
        let allTextFiles = extractAllFile(atPath: testPart.testPath, withExtension: "pas")
        for file in allTextFiles {
            errorMessages.removeAll()
            print(file)
            do {
                let progText = try String(contentsOf: NSURL.fileURL(withPath: file))
                let outPut = (file.replacingOccurrences(of: ".pas", with: ".out"))
                
                let result = getResult(testPart.method, progText)
                
                do {
                    try result.write(to: NSURL.fileURL(withPath: outPut), atomically: true, encoding: .utf8)
                }
                catch {
                    print("Can't create file: \(file)")
                }
            } catch {
                print("Error loading contents of:", file, error)
            }
        }
    }
default:
    do {
        if(fileName != nil) {
            let fileManager = FileManager.default
            let path = fileManager.currentDirectoryPath
            let progText = try String(contentsOf: NSURL.fileURL(withPath: path + "/" + fileName!))
            print(progText)
            print(getResult(usualMod, progText))
        }
    } catch {
        print("Error loading contents of:", fileName!, error)
    }
}
//let testText  = """
//a = array[1 ..5] of integer;
//"""
//let LexAnalyzer = Tokenizer(text: testText)
//print(LexAnalyzer.test())



