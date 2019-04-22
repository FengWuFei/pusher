import TaskKit
import Foundation

public class PushTask: Task {
    public var option: TaskParsedOptionsInfo
    public var process: Process?
    public var onError: ((Error) -> Void)?
    public var taskArguments: [String] {
        return [
            "-i", "\(sourceUrl)",
            "-codec", "copy",
            "-bsf:a", "aac_adtstoasc",
            "-f", "flv",
            "\(targetUrl)"
        ]
    }
    public var identifier: String {
        return targetUrl
    }
    
    var sourceUrl: String
    var targetUrl: String
    
    public init(sourceUrl: String, targetUrl: String, optionsInfo: TaskOptionsInfo) {
        self.sourceUrl = sourceUrl
        self.targetUrl = targetUrl
        self.option = TaskParsedOptionsInfo(optionsInfo + [.taskType(.forever), .quality(.userInteractive)])
    }
}
