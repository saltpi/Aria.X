import Foundation

enum ShellError: Error {
    case commandFailed(command: String, exitCode: Int32, output: String)
}

struct Shell {
    @discardableResult
    static func run(_ command: String, currentDirectory: URL? = nil, environment: [String: String]? = nil) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        
        if let currentDirectory = currentDirectory {
            process.currentDirectoryURL = currentDirectory
        }
        
        var currentEnv = ProcessInfo.processInfo.environment
        if let environment = environment {
            for (key, value) in environment {
                currentEnv[key] = value
            }
        }
        process.environment = currentEnv
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if process.terminationStatus != 0 {
            throw ShellError.commandFailed(command: command, exitCode: process.terminationStatus, output: errorOutput.isEmpty ? output : errorOutput)
        }
        
        return output
    }
}
