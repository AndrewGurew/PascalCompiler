//
//  Generator.swift
//  AGPC
//
//  Created by Andrey Gurev on 13.12.2017.
//  Copyright © 2017 Andrey Gurev. All rights reserved.


import Foundation

enum CommandType {
    case BR, ALLOC, STORE, LABEL, CAST, EXPR, WRITE, LOAD, FUNC, FUNCEND, CALL
}

enum LLVarType: String {
    case I32 = "i32", DOUBLE = "double", UN = "UN", VOID = "void"
}

class Llvm {
    let type: CommandType
    init(type: CommandType) {
        self.type = type
    }
    
    func getCommand() -> String {
        preconditionFailure()
    }
}

class LLCall: Llvm {
    var paramList:[(LLVarType, String)]
    var name: String
    var returnType:LLVarType
    init(_ paramList:[(LLVarType, String)],_ name:String,_ returnType: LLVarType) {
        self.name = name
        self.returnType = returnType
        self.paramList = paramList
        super.init(type: .CALL)
    }
    
    override func getCommand() -> String {
        var paramStr = "( "
        for param in paramList {
            paramStr += "\(param.0.rawValue)* %\(param.1),"
        }
        
        paramStr.removeLast()
        paramStr.append(")")
        
        return "call \(returnType.rawValue) @\(name) \(paramStr)\n"
    }
}

class LLFunc: Llvm {
    var returnType:LLVarType
    var name:String
    var paramList:[(LLVarType, String)]
    
    
    init(_ returnType: LLVarType,_ name: String,_ paramList:[(LLVarType, String)]) {
        self.returnType = returnType
        self.name = name
        self.paramList = paramList
                //labelIndex -= 1
        super.init(type: .FUNC)
    }
    
    override func getCommand() -> String {
        var paramStr = "( "
        for param in paramList {
            paramStr += "\(param.0.rawValue)* %\(param.1),"
        }
        
        paramStr.removeLast()
        paramStr.append(")")
        
        return "define \(returnType.rawValue) @\(name) \(paramStr) {\n"
    }
}

class LLFuncEnd: Llvm {
    var returnType:LLVarType
    var returnValue: String?
    init(_ returnType: LLVarType,_ returnValue: String? = nil) {
        self.returnType = returnType
        self.returnValue = returnValue
        super.init(type: .FUNCEND)
    }
    
    override func getCommand() -> String {
        return "ret \(returnType.rawValue) \(returnValue ?? "")\n}\n"
    }
}

class LLWriteln: Llvm {
    var formatList: [String]
    var outVariables: [(LLVarType, String)]
    var index = 0
    init(_ formatList:[String],_ outVariables:[(LLVarType, String)],_ index: Int) {
        labelIndex+=1
        self.formatList = formatList
        self.outVariables = outVariables
        self.index = index
        super.init(type: .LABEL)
    }
    
    override func getCommand() -> String {
        var format = ""
        for f in formatList { format += f }
        
        var outputVariables = ""
        for f in outVariables { outputVariables +=  "\(f.0.rawValue) \(f.1)" + ","}
        outputVariables.removeLast()
        
        if (writelnDeclared.index(forKey: formatList.count) == nil) || (writelnDeclared[formatList.count] == false) {
            _globalDeclare += "@hello\(formatList.count) = private constant [\(format.length) x i8] c\"\(format)\"\n";
            writelnDeclared[formatList.count] = true
        }
        
        let ptrDeclare = "%ptr\(self.index) = bitcast [\(format.length) x i8] * @hello\(formatList.count) to i8*\n"
        
        return ptrDeclare + "call i32 (i8*, ...) @printf(i8* %ptr\(self.index), \(outputVariables))\n"
    }
}

class LLLabel: Llvm {
    var labelNumber: Int
    init() {
        labelIndex+=1
        labelNumber = labelIndex
        super.init(type: .LABEL)
    }
    
    override func getCommand() -> String {
        return "; <label>:\(self.labelNumber)\n"
    }
}

class LLAlloc: Llvm {
    let name: String
    let allocType: LLVarType
    init(_ name: String,_ type: LLVarType) {
        self.name = name
        self.allocType = type
        super.init(type: .ALLOC)
    }
    
    override func getCommand() -> String {
        return "%\(name) = alloca \(allocType.rawValue), align 4\n"
    }
}

class LLStore: Llvm {
    let value: String
    let storeType: LLVarType
    let name: String
    init(_ value: String,_ type: LLVarType,_ name: String) {
        self.storeType = type
        self.value = value
        self.name = name
        super.init(type: .STORE)
    }
    
    override func getCommand() -> String {
        return "store \(storeType.rawValue) \(value), \(storeType.rawValue)* %\(name), align 4\n"
    }
    
}

class LLExpression: Llvm {
    
    enum Oper: String {
        case
        FSUB = "fsub", SUB = "sub",
        FMUL = "fmul", MUL = "mul",
        FDIV = "fdiv", DIV = "sdiv",
        SREM = "srem",
        AND = "and", OR = "or",
        ADD = "add", FADD = "fadd"
        case
        FOEQ = "fcmp oeq", EQ = "icmp eq",
        FONE = "fcmp one", NE = "icmp ne",
        FOGT = "fcmp ogt", SGT = "icmp sgt",
        FOGE = "fcmp oge", SGE = "icmp sge",
        FOLT = "fcmp olt", SLT = "icmp slt",
        FOLE = "fcmp ole", SLE = "icmp sle"
    }
    
    let leftChild: String
    let rightChild: String
    let exprType: LLVarType
    let oper: Oper
    let name: String

    init(_ oper: Oper,_ type: LLVarType,_ leftChild: String,_ rightChild: String,_ name: String) {
        self.oper = oper
        self.name = name
        self.exprType = type
        self.leftChild = leftChild
        self.rightChild = rightChild
        super.init(type: .EXPR)
    }
    
    override func getCommand() -> String {
        return "\(self.name) = \(self.oper.rawValue) \(exprType.rawValue) \(leftChild), \(rightChild)\n"
    }
}

class LLLoad: Llvm {
    var name: String
    var loadType: LLVarType
    var fromType: LLVarType
    var fromName: String
    init(_ name: String,_ loadType: LLVarType,_ fromType: LLVarType,_ fromName: String) {
        self.name = name
        self.loadType = loadType
        self.fromType = fromType
        self.fromName = fromName
        super.init(type: .LOAD)
    }
    
    override func getCommand() -> String {
        return "\(name) = load \(loadType.rawValue), \(fromType.rawValue)* %\(fromName), align 4\n"
    }
}

class LLCast: Llvm {
    var name: String
    var fromName: String
    var fromType: LLVarType
    var toType: LLVarType
    init(_ fromName: String,_ fromType: LLVarType,_ toType: LLVarType) {
        self.fromName = fromName
        self.name = "\(fromName)cast"
        self.fromType = fromType
        self.toType = toType
        super.init(type: .CAST)
    }
    
    override func getCommand() -> String {
        return "\(self.name) = sitofp \(self.fromType.rawValue) \(self.fromName) to \(self.toType.rawValue)\n"
    }
}

class LLBr: Llvm {
    private var resultCommand: String = ""
    var jumpTo: LLLabel?
    var elseJumpTo: LLLabel?
    var conditionName: String?
    
    init(_ condition: String,_ jumpTo: LLLabel,_ elseJumpTo: LLLabel) {
        self.conditionName = condition
        self.jumpTo = jumpTo
        self.elseJumpTo = elseJumpTo
        super.init(type: .BR)
    }
    
    init(_ jumpTo: LLLabel) {
        self.jumpTo = jumpTo
        super.init(type: .BR)
    }
    
    init() {
        super.init(type: .BR)
    }
    
    override func getCommand() -> String {
        if (jumpTo != nil && elseJumpTo != nil) {
            resultCommand = "br i1 \(conditionName!), label %\(jumpTo!.labelNumber), label %\(elseJumpTo!.labelNumber)\n"
        } else if (jumpTo != nil) {
            resultCommand = "br label %\(jumpTo!.labelNumber)\n"
        } else {
            resultCommand = ""
        }
        return resultCommand
    }
}

class LLTransition: LLBr {
    enum TransKind {
        case CONTINUE, BREAK
    }
    var lablel: LLLabel?
    var kind: TransKind
    
    init(kind: TransKind) {
        self.kind = kind
        super.init()
    }
    
    func setJumpPoit(point: LLLabel) {
        self.lablel = point
        super.jumpTo = self.lablel
    }
}

func createBreak(_ blockArr: inout [Llvm],_ exitPint: LLLabel, _ conditionPoint: LLLabel) {
    var remove = false
    var len = blockArr.count
    var i = 0
    while (i < blockArr.count) {
        if let llb = (blockArr[i] as? LLTransition)  {
            if (llb.lablel == nil && llb.kind == .BREAK && !remove) {
                llb.setJumpPoit(point: exitPint)
                remove = true
                i += 1
                continue
            }
        }
        
        if let llc = (blockArr[i] as? LLTransition)  {
            if (llc.lablel == nil && llc.kind == .CONTINUE && !remove) {
                llc.setJumpPoit(point: conditionPoint)
                remove = true
                i += 1
                continue
            }
        }
        
        if (blockArr[i] is LLLabel) {
            remove = false
        } else {
            if (remove) {
                blockArr.remove(at: i)
                len -= 1
                continue
            }
        }
        i += 1
    }
}

struct LlvmVariable {
    var name: String
    var type: LLVarType
    init(_ name:String,_ type: LLVarType) {
        self.name = name
        self.type = type
    }
}

var waitingForPoint:[LLLabel] = []

var llvmVarStack:[String:LlvmVariable] = [:]
struct Program {
    var global:[Llvm] = []
    var declaration:[Llvm] = []
    var block:[Llvm] = []
}

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

class CodeGenerator {
    private let mainBlock: Block
    private var llvmText: String = ""
    private var globalDeclare: String = ""
    
    private var program = Program()
    
    init(block: Block) {
        self.mainBlock = block
        
    }
    
    public func generate() {
        initGenerator()
        self.llvmText = "define i32 @main() \n{"
        generateDeclaration(declScope: self.mainBlock.declScope)
        generateStatements(block: self.mainBlock)
        self.toText()
        self.llvmText += "ret i32 0 \n}"
        
        self.llvmText = _globalDeclare + globalDeclare + self.llvmText
        
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
            try self.getLLVM().write(toFile: "\(path)h.ll", atomically: false, encoding: .utf8)
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
    
    private func generateDeclaration(declScope: DeclarationScope?) {
        if (declScope == nil) {
            return
        }
        for (_, value) in (declScope?.declList)! {


  
                program.declaration.append(contentsOf: value.generate())
            
        }
    }
    
    private func generateStatements(block: Block) {
        program.declaration.append(contentsOf: block.generate())
        self.globalDeclare = "declare i32 @printf(i8*, ...)\n"
        //return result
    }
    
    private func toText() {
        for gloabl in program.global {
            self.globalDeclare += gloabl.getCommand()
        }
        
        var gloabal = false
        for decl in program.declaration {
            if !(gloabal) {
            gloabal = (decl is LLFunc)
            }
            
            if(gloabal) {
                self.globalDeclare += decl.getCommand()
            } else {
                self.llvmText += decl.getCommand()
            }
            if (gloabal) {
            gloabal = !(decl is LLFuncEnd)
            }
        }
        
        for stmt in program.block {
            self.llvmText += stmt.getCommand()
        }
    }
}
