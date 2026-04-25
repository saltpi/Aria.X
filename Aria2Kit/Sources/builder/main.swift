import Foundation

let builder = Aria2Builder()

do {
    try builder.buildAll()
    print("Build completed successfully!")
} catch {
    print("Build failed: \(error)")
    exit(1)
}
