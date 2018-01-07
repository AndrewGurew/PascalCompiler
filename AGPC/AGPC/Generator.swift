//
//  Generator.swift
//  AGPC
//
//  Created by Andrey Gurev on 13.12.2017.
//  Copyright © 2017 Andrey Gurev. All rights reserved.


import Foundation

struct LlvmVariable {
    var name: String
    var type: String
    init(_ name:String,_ type: String) {
        self.name = name
        self.type = type
    }
}

var llvmVarStack:[String:LlvmVariable] = [:]

class CodeGenerator {
    private let mainBlock: Block
    private var llvmText: String = ""
    private var globalDeclare: String = ""
    
    init(block: Block) {
        self.mainBlock = block
    }
    
    public func generate() {
        initGenerator()
        self.llvmText = "define i32 @main() \n{"
        self.llvmText += generateDeclaration(declScope: self.mainBlock.declScope)
        self.llvmText += generateStatements(block: self.mainBlock)
        self.llvmText += "ret i32 0 \n}"
        
        self.llvmText = globalDeclare + self.llvmText
        
    }
    
    private func runCommand(cmd : String, args : String...) -> (output: [String], error: [String], exitCode: Int32) {
        
        var output : [String] = []
        var error : [String] = []
        
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        
        task.launch()
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: "\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: "\n")
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        return (output, error, status)
    }
    
    public func run() -> String {
        generate()
        llvmVarStack = [:]
        let path = "/Users/Andrey/Desktop/Swift/PascalCompiler/AGPC/llvm/"
        
        do {
            try self.getLLVM().write(toFile: "/Users/Andrey/Desktop/Swift/PascalCompiler/AGPC/llvm/h.ll", atomically: false, encoding: .utf8)
        }
        catch {
            print("Writing error")
        }
        var result = ""
        var error = ""
        for e in runCommand(cmd: "\(path)./llc", args: "\(path)h.ll", "-filetype=obj").error {
            if !(e.isEmpty) {
                error.append(e + "\n")
            }
        }
        
        for e in runCommand(cmd: "\(path)./ld", args: "\(path)h.o", "\(path)libc++.a", "-lc", "-e", "_main", "-arch", "x86_64", "-macosx_version_min", "10.13", "-lSystem", "-o", "\(path)a.out").error {
            if !(e.isEmpty) {
                error.append(e + "\n")
            }
        }

        for mess in runCommand(cmd: "\(path)./a.out").output {
            result += mess
            if(result.last?.asciiValue == 1) {
                result.removeLast()
            }
        }
        return error + result;
    }
    
    public func getLLVM() -> String {
        return self.llvmText
    }
    
    private func generateDeclaration(declScope: DeclarationScope?) -> String {
        if (declScope == nil) {
            return ""
        }
        var result = ""
        for (_, value) in (declScope?.declList)! {
            result += value.generate()
        }
        return result
    }
    
    private func generateStatements(block: Block) -> String {
        let result = block.generate()
        self.globalDeclare = _globalDeclare + "declare i32 @printf(i8*, ...)\n"
        return result
    }
}
