import Foundation
import CommandLineKit
import Rainbow
import TaskKit

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
let mulAddress = MultiStringOption(shortFlag: "m", longFlag: "multi", required: true,
                                   helpMessage: "[必需]组播地址范围,例如：225.1.10.1-20:2000 225.2.10.3-20:2000")
let target = StringOption(shortFlag: "t", longFlag: "target",
                       helpMessage: "[可选]目的rtmp地址，默认: rtmp://10.15.100.224/live/")
let path = StringOption(shortFlag: "p", longFlag: "Path",
                          helpMessage: "[可选]ffmpeg可执行文件地址，默认: /usr/local/bin/ffmpeg")
cli.addOptions(streamName, mulAddress, target, path)

do {
    try cli.parse()
} catch {
    cli.printUsage(error)
    exit(EX_USAGE)
}

let name = streamName.value!
let addressValue = mulAddress.value!
let targetAddress = target.value ?? "rtmp://10.15.100.224/live/"
let executablePath = path.value ?? "/usr/local/bin/ffmpeg"

func assertNotNil<T>(_ value: Optional<T>, message: String) -> T {
    guard let res = value else {
        print("wraong: \(message) is nil".red.bold)
        exit(EX_USAGE)
    }
    return res
}

func assertArrayCount<T>(array: [T], count: Int) {
    if array.count != count {
        print("wraong: \(array)".red.bold)
        exit(EX_USAGE)
    }
}

var addressArray = [String]()
addressValue.forEach { v in
    if v.contains("-") {
        let strs = v.split(separator: "-")
        assertArrayCount(array: strs, count: 2)
        var topList = strs[0].split(separator: ".")
        var bottomList = strs[1].split(separator: ":")
        assertArrayCount(array: topList, count: 4)
        assertArrayCount(array: bottomList, count: 2)

        let startIndex = assertNotNil(Int(String(topList[3])), message: "startIndex")
        let endIndex = assertNotNil(Int(String(bottomList[0])), message: "endIndex")
        (startIndex...endIndex).forEach { index in
            topList[3] = Substring.SubSequence(String(index))
            let res = topList.joined(separator: ".") + ":" + String(bottomList[1])
            addressArray.append(res)
        }
    } else {
        addressArray.append(v)
    }
}

var streamIndex = 0
let tasks = addressArray.map { address -> Task in
    streamIndex += 1
    let task = PushTask(sourceUrl: "udp://\(address)",
        targetUrl: "\(targetAddress)\(name)\(streamIndex)",
        optionsInfo: [.executablePath(executablePath)])
    return task
}
let manager = TaskManager.shared
tasks.forEach { manager.addTask($0) }
manager.fireAll()

func exitGracefully(pid: CInt) {
    print("stopping...".red.underline)
    manager.cancelAll()
    exit(EX_USAGE)
}

signal(SIGINT, exitGracefully)
signal(SIGTERM, exitGracefully)
print("推流中...".green.bold)

let lock = ConditionLock(value: 0)
lock.lock(whenValue: 1)
