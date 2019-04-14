import CommandLineKit
import Rainbow
import Foundation

let cli = CommandLineKit.CommandLine()

cli.formatOutput = { s, type in
    var str: String
    switch(type) {
    case .error:
        str = s.red.bold
    case .optionFlag:
        str = s.green.underline
    case .optionHelp:
        str = s.blue
    default:
        str = s
    }
    return cli.defaultFormat(s: str, type: type)
}

let filePath = StringOption(shortFlag: "f", longFlag: "file", required: true,
                            helpMessage: "Path to the output file.")
let compress = BoolOption(shortFlag: "c", longFlag: "compress",
                          helpMessage: "Use data compression.")
let help = BoolOption(shortFlag: "h", longFlag: "help",
                      helpMessage: "Prints a help message.")
let verbosity = CounterOption(shortFlag: "v", longFlag: "verbose",
                              helpMessage: "Print verbose messages. Specify multiple times to increase verbosity.")

cli.addOptions(filePath, compress, help, verbosity)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

print("File path is \(filePath.value!)")
print("Compress is \(compress.value)")
print("Verbosity is \(verbosity.value)")

//@discardableResult
//func newTaskAndRun(
//    qualityOfService: QualityOfService = .userInitiated,
//    executablePath: String,
//    directoryPath: String,
//    arguments: [String],
//    terminationHandler: @escaping () -> Void) -> Process {
//    let task = Process()
//    if #available(OSX 10.13, *) {
//        task.executableURL = URL(fileURLWithPath: executablePath)
//        task.currentDirectoryURL = URL(fileURLWithPath: directoryPath, isDirectory: true)
//    } else {
//        fatalError("version should be OSX 10.13+")
//    }
//    task.qualityOfService = qualityOfService
//    task.arguments = arguments
//    task.terminationHandler = { _ in
//        terminationHandler()
//    }
//    task.launch()
//    return task
//}
//
//let arguments = (1...30).map {
//    return [
//        "-re",
//        "-i", "udp://226.151.1.\($0):2000?overrun_nonfatal=1&fifo_size=50000000",
//        "-vcodec", "copy",
//        "-acodec", "copy",
//        "-bsf:a", "aac_adtstoasc",
//        "-f", "flv",
//        "rtmp://10.15.100.224/live/swift\($0)"
//    ]
//}
//
//func pushStream(arguments: [String]) -> Process {
//    let p =  newTaskAndRun(executablePath: "/usr/bin/ffmpeg", directoryPath: "/home", arguments: arguments) {
//        print("exit: \(arguments[2])")
//    }
//    return p
//}
//
//var plist = [Process]()
//
//arguments.forEach { arguments in
//    let p = pushStream(arguments: arguments)
//    plist.append(p)
//}

func exitGracefully(pid: CInt) {
//    plist.forEach { $0.terminate() }
    print("exitGracefully: \(pid)")
    exit(EX_USAGE)
}

signal(SIGINT, exitGracefully)
signal(SIGTERM, exitGracefully)
dispatchMain()
