import CommandLineKit
import Rainbow
import Foundation

let cli = CommandLineKit.CommandLine()

cli.formatOutput = { str, type in
    var string: String
    switch(type) {
    case .error:
        string = str.red.bold
    case .optionFlag:
        string = str.green
    case .optionHelp:
        string = str.lightMagenta
    default:
        string = str
    }
    return cli.defaultFormat(s: string, type: type)
}

let streamName = StringOption(shortFlag: "n", longFlag: "name", required: true,
                            helpMessage: "[必需]视频流名字")
let startAddress = StringOption(shortFlag: "s", longFlag: "start", required: true,
                                helpMessage: "[必需]开始的组播地址,例如：225.1.10.1:2000")
let streamCount = IntOption(shortFlag: "c", longFlag: "count", required: true,
                            helpMessage: "[必需]推流数量，例如：10")
let shouldOut = BoolOption(shortFlag: "o", longFlag: "out",
                           helpMessage: "[可选]默认不输出, 需要输出: -o true")
let target = StringOption(shortFlag: "t", longFlag: "target",
                       helpMessage: "[可选]目的rtmp地址，默认: rtmp://10.15.100.224/live/")
let help = BoolOption(shortFlag: "h", longFlag: "help",
                      helpMessage: "[可选]帮助说明")
cli.addOptions(streamName, startAddress, streamCount, shouldOut, target, help)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

let name = streamName.value!
let startAddressValue = startAddress.value!
let streamCountValue = streamCount.value!
let shouldOutValue = shouldOut.value
let targetAddress = target.value ?? "rtmp://10.15.100.224/live/"

if help.value {
    cli.printUsage()
    exit(EX_USAGE)
}

@discardableResult
func newTaskAndRun(
    qualityOfService: QualityOfService = .userInitiated,
    executablePath: String,
    directoryPath: String,
    arguments: [String],
    terminationHandler: @escaping () -> Void) -> Process {
    let task = Process()
    if #available(OSX 10.13, *) {
        task.executableURL = URL(fileURLWithPath: executablePath)
        task.currentDirectoryURL = URL(fileURLWithPath: directoryPath, isDirectory: true)
    } else {
        fatalError("version should be OSX 10.13+")
    }

    if !shouldOutValue {
        let out = Pipe()
        let error = Pipe()
        task.standardOutput = out
        task.standardError = error
    }
    task.qualityOfService = qualityOfService
    task.arguments = arguments
    task.terminationHandler = { _ in
        terminationHandler()
    }
    task.launch()
    return task
}

let str = startAddressValue
var slices = str.split(separator: ".")
var endStr = slices[3].split(separator: ":")
let startNum = Int(endStr[0])!

let arguments = (startNum...(startNum + streamCountValue - 1)).map { num -> [String] in
    endStr[0] = Substring(String(num))
    slices[3] = Substring(endStr.joined(separator: ":"))
    let udpAddress = slices.joined(separator: ".")
    return [
        "-re",
        "-i", "udp://\(udpAddress)?overrun_nonfatal=1&fifo_size=50000000",
        "-vcodec", "copy",
        "-acodec", "copy",
        "-bsf:a", "aac_adtstoasc",
        "-f", "flv",
        "\(targetAddress)\(name)\(num)"
    ]
}

func pushStream(arguments: [String]) -> Process {
    let p =  newTaskAndRun(executablePath: "/usr/bin/ffmpeg", directoryPath: "/home", arguments: arguments) {
        print("exit: \(arguments[2])".red.underline.bold)
    }
    return p
}

var plist = [Process]()

arguments.forEach { arguments in
    let p = pushStream(arguments: arguments)
    plist.append(p)
}

func exitGracefully(pid: CInt) {
    plist.forEach { $0.terminate() }
    print("exitGracefully: \(pid)")
    exit(EX_USAGE)
}

signal(SIGINT, exitGracefully)
signal(SIGTERM, exitGracefully)
dispatchMain()
