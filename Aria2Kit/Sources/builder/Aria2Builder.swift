import Foundation

struct Aria2Builder {
    let version = "1.37.0"
    let workingDirectory: URL
    let artifactsDirectory: URL
    
    init() {
        self.workingDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".build-aria2")
        self.artifactsDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("artifacts")
    }
    
    func buildAll() throws {
        try setupDirectories()
        let sourceDir = try downloadSource()
        try patchSource(sourceDir: sourceDir)
        
        let platforms: [(name: String, sdk: String, architectures: [String])] = [
            ("macosx", "macosx", ["x86_64", "arm64"]),
            ("iphoneos", "iphoneos", ["arm64"]),
            ("iphonesimulator", "iphonesimulator", ["x86_64", "arm64"])
        ]
        
        var libraryPaths: [URL] = []
        
        for platform in platforms {
            var archLibs: [URL] = []
            for arch in platform.architectures {
                print("Building for \(platform.name) - \(arch)...")
                let libPath = try build(sourceDir: sourceDir, platform: platform.name, sdk: platform.sdk, arch: arch)
                archLibs.append(libPath)
            }
            
            // Combine architectures for the same platform if necessary
            if archLibs.count > 1 {
                let fatLib = try lipo(libs: archLibs, platform: platform.name)
                libraryPaths.append(fatLib)
            } else {
                libraryPaths.append(archLibs[0])
            }
        }
        
        try createXCFramework(libraryPaths: libraryPaths, includeDir: sourceDir.appendingPathComponent("src/includes"))
    }
    
    private func setupDirectories() throws {
        if FileManager.default.fileExists(atPath: workingDirectory.path) {
            try FileManager.default.removeItem(at: workingDirectory)
        }
        try FileManager.default.createDirectory(at: workingDirectory, withIntermediateDirectories: true)
        
        if !FileManager.default.fileExists(atPath: artifactsDirectory.path) {
            try FileManager.default.createDirectory(at: artifactsDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func downloadSource() throws -> URL {
        print("Downloading aria2 source...")
        let tarballName = "aria2-\(version).tar.gz"
        let url = "https://github.com/aria2/aria2/releases/download/release-\(version)/\(tarballName)"
        let tarballPath = workingDirectory.appendingPathComponent(tarballName)
        
        try Shell.run("curl -L \(url) -o \(tarballPath.path)")
        try Shell.run("tar -xzf \(tarballPath.path) -C \(workingDirectory.path)")
        
        return workingDirectory.appendingPathComponent("aria2-\(version)")
    }
    
    private func patchSource(sourceDir: URL) throws {
        print("Patching source for iOS compatibility...")
        let file = sourceDir.appendingPathComponent("src/AppleTLSSession.cc")
        // Comment out SSLSetDiffieHellmanParams which is not available on modern iOS
        try Shell.run("sed -i '' 's/lastError_ = SSLSetDiffieHellmanParams/\\/\\/ lastError_ = SSLSetDiffieHellmanParams/g' \(file.path)")
    }
    
    private func build(sourceDir: URL, platform: String, sdk: String, arch: String) throws -> URL {
        let buildDir = workingDirectory.appendingPathComponent("build-\(platform)-\(arch)")
        try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
        
        let sdkPath = try Shell.run("xcrun --sdk \(sdk) --show-sdk-path")
        let clangPath = try Shell.run("xcrun --sdk \(sdk) -f clang")
        let clangPlusPlusPath = try Shell.run("xcrun --sdk \(sdk) -f clang++")
        
        let deploymentTarget: String
        let target: String
        
        if platform == "iphoneos" {
            deploymentTarget = "17.0"
            target = "arm64-apple-ios\(deploymentTarget)"
        } else if platform == "iphonesimulator" {
            deploymentTarget = "17.0"
            target = "\(arch)-apple-ios\(deploymentTarget)-simulator"
        } else {
            deploymentTarget = "14.0"
            target = "\(arch)-apple-macosx\(deploymentTarget)"
        }
        
        let cflags = "-target \(target) -isysroot \(sdkPath) -O3"
        let env = [
            "CC": clangPath,
            "CXX": clangPlusPlusPath,
            "CFLAGS": cflags,
            "CXXFLAGS": cflags,
            "LDFLAGS": "-target \(target) -isysroot \(sdkPath)",
            "IPHONEOS_DEPLOYMENT_TARGET": deploymentTarget,
            "MACOSX_DEPLOYMENT_TARGET": platform == "macosx" ? deploymentTarget : "",
            "LIBXML2_CFLAGS": "-I\(sdkPath)/usr/include/libxml2",
            "LIBXML2_LIBS": "-lxml2",
            "ZLIB_CFLAGS": "-I\(sdkPath)/usr/include",
            "ZLIB_LIBS": "-lz",
            "SQLITE3_CFLAGS": "-I\(sdkPath)/usr/include",
            "SQLITE3_LIBS": "-lsqlite3"
        ]
        
        let configureArgs = [
            "--host=\(arch == "arm64" ? "aarch64" : "x86_64")-apple-darwin",
            "--prefix=\(buildDir.path)",
            "--enable-static",
            "--disable-shared",
            "--enable-libaria2", // 关键：开启库接口编译
            "--without-gnutls",
            "--with-appletls",
            "--without-libgmp",
            "--without-libnettle",
            "--without-libssh2",
            "--without-libcares",
            "--disable-nls",
            "--with-libxml2",
            "--with-sqlite3",
            "--with-zlib"
        ].joined(separator: " ")
        
        // Clean and configure
        try Shell.run("make clean || true", currentDirectory: sourceDir)
        try Shell.run("./configure \(configureArgs)", currentDirectory: sourceDir, environment: env)
        try Shell.run("make -j$(sysctl -n hw.ncpu)", currentDirectory: sourceDir, environment: env)
        
        let libAria2 = sourceDir.appendingPathComponent("src/.libs/libaria2.a")
        let destLib = buildDir.appendingPathComponent("libaria2.a")
        try FileManager.default.copyItem(at: libAria2, to: destLib)
        
        return destLib
    }
    
    private func lipo(libs: [URL], platform: String) throws -> URL {
        let output = workingDirectory.appendingPathComponent("libaria2-\(platform).a")
        try? FileManager.default.removeItem(at: output)
        let libsList = libs.map { $0.path }.joined(separator: " ")
        try Shell.run("lipo -create \(libsList) -output \(output.path)")
        return output
    }
    
    private func createXCFramework(libraryPaths: [URL], includeDir: URL) throws {
        print("Creating XCFramework...")
        let outputPath = artifactsDirectory.appendingPathComponent("Aria2.xcframework")
        if FileManager.default.fileExists(atPath: outputPath.path) {
            try FileManager.default.removeItem(at: outputPath)
        }
        
        // Prepare a clean include directory for the XCFramework
        let finalIncludeDir = workingDirectory.appendingPathComponent("include")
        let aria2IncludeDir = finalIncludeDir.appendingPathComponent("aria2")
        try? FileManager.default.removeItem(at: finalIncludeDir)
        try FileManager.default.createDirectory(at: aria2IncludeDir, withIntermediateDirectories: true)
        
        // Copy the public header
        let publicHeader = includeDir.appendingPathComponent("aria2/aria2.h")
        try FileManager.default.copyItem(at: publicHeader, to: aria2IncludeDir.appendingPathComponent("aria2.h"))
        
        var cmd = "xcodebuild -create-xcframework "
        for lib in libraryPaths {
            // Ensure every library is named libaria2.a for consistency
            let tempDir = workingDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            let renamedLib = tempDir.appendingPathComponent("libaria2.a")
            try FileManager.default.copyItem(at: lib, to: renamedLib)
            
            cmd += "-library \(renamedLib.path) -headers \(finalIncludeDir.path) "
        }
        
        cmd += "-output \(outputPath.path)"
        
        try Shell.run(cmd)
        print("XCFramework created at \(outputPath.path)")
    }
}
