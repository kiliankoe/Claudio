import Foundation
import Combine

class ConversionHandler: ObservableObject {
    @Published var state: ConversionState = .waiting

    func run(withFile path: URL) {
        do {
            try run(filePath: path)
        } catch let error as ConversionError {
            self.set(state: .error(error))
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    private func set(state: ConversionState) {
        DispatchQueue.main.async {
            self.state = state
        }
    }

    private func run(filePath: URL) throws {
        guard filePath.pathExtension == "flac" else { throw ConversionError.unexpectedFiletype }
        let outputPath = filePath.spaceEscapedPath.replacingOccurrences(of: ".flac", with: ".m4a")
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "ffmpeg -i \(filePath.spaceEscapedPath) -acodec alac \(outputPath) -y"]

        print("Running: ")
        print("\(task.launchPath!) \(task.arguments!.joined(separator: " "))")

        self.set(state: .converting(filename: filePath.lastPathComponent))

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        output.map { print($0) }
        task.waitUntilExit()

        if task.terminationStatus != 0 {
            throw ConversionError.taskFailed
        }

        self.set(state: .finished)
    }
}

enum ConversionState: Equatable {
    case waiting
    case converting(filename: String)
    case error(ConversionError)
    case finished
}

enum ConversionError: String, Error, LocalizedError {
    case unexpectedFiletype = "Expected FLAC file"
    case taskFailed = "ffmpeg exited with error"

    var errorDescription: String? {
        self.rawValue
    }
}

extension URL {
    var spaceEscapedPath: String {
        path.replacingOccurrences(of: " ", with: "\\ ")
    }
}
