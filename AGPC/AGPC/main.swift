//
//  main.swift
//  AGPC
//
//  Created by Andrey Gurev on 06.10.17.
//  Copyright © 2017 Andrey Gurev. All rights reserved.
//  

import Foundation

func lexTabale(progText: String) -> String {
    let lexAnalyzer = Tokenizer(text: progText)
    return lexAnalyzer.lexemTable(lexAnalyzer.lexems)
}

func exTree(progText: String) -> String {
    let lexAnalyzer = Tokenizer(text: progText)
    let expressionParser = Parser(tokenizer: lexAnalyzer)
    return expressionParser.getTreeAsStr()
}

enum Mod {
    case RELEASE
    case TEST
    case GEN_TEST_ANSWERS
    case HELP
}

typealias Method = (String) -> String

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
    Test("Expression tests:\n", exTree, "/Users/Andrey/Desktop/Swift/PascalCompiler/Tests/Expressions")
]

var mod:Mod = .RELEASE
var keys = [String]()
var fileName:String?

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
    for testPart in testParts {
        print("\n\(testPart.text)")
        let allTextFiles = extractAllFile(atPath: testPart.testPath, withExtension: "pas")
        for file in allTextFiles {
            do {
                let progText = try String(contentsOf: NSURL.fileURL(withPath: file))
                let result = testPart.method(progText)
                
                let outPut = (file.replacingOccurrences(of: ".pas", with: ".out"))
                let ansText = try String(contentsOf: NSURL.fileURL(withPath: outPut))
                
                var testResult = "Test number \(allTextFiles.index(of: file)! + 1) - "
                (result == ansText) ? testResult.append("OK") : testResult.append("NO")
                print(testResult)
                
            } catch {
                print("Error loading contents of:", file, error)
            }
        }
    }
case .GEN_TEST_ANSWERS:
    for testPart in testParts {
        let allTextFiles = extractAllFile(atPath: testPart.testPath, withExtension: "pas")
        for file in allTextFiles {
                    print(file)
            do {
                let progText = try String(contentsOf: NSURL.fileURL(withPath: file))
                let result = testPart.method(progText)
                let outPut = (file.replacingOccurrences(of: ".pas", with: ".out"))
                
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
            let LexAnalyzer = Tokenizer(text: progText)
            
            if(keys.index(of: "-l") != nil) {
                print(LexAnalyzer.lexemTable(LexAnalyzer.lexems))
            }
            if(keys.index(of: "-e") != nil) {
                let ExpressionParser = Parser(tokenizer: LexAnalyzer)
                print(ExpressionParser.getTreeAsStr())
            }
        }
    } catch {
        print("Error loading contents of:", fileName!, error)
    }
}
//let testText  = "1.5 + 3.3333;"
//let LexAnalyzer = Tokenizer(text: testText)
//let ExpressionParser = Parser(tokenizer: LexAnalyzer)
//print(ExpressionParser.getTreeAsStr())



