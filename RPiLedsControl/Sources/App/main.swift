#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

import Vapor
import SwiftyGPIO
import SwiftGPIOLibrary

extension Optional {
	// `then` function executes the closure if there is some value
	func then(_ handler: (Wrapped) -> Void) {
		switch self {
		case .some(let wrapped): return handler(wrapped)
		case .none: break
		}
	}
}

enum Command {
    static let Zero = 0
    static let One = 1
    static let Two = 2
}

let gpioLib = GPIOLib.sharedInstance
// Setup pin 20 and 26 as output with value 0
let list: [GPIOName] = [.P20, .P26]
let ports = gpioLib.setupOUT(ports: list, for: .RaspberryPi2)

func yellow() {
    if (gpioLib.status(ports[.P20]) == 0) {
        gpioLib.switchOn(ports: [.P20])
    } else {
        gpioLib.switchOff(ports: [.P20])
    }
}

func green() {
    if (gpioLib.status(ports[.P26]) == 0) {
        gpioLib.switchOn(ports: [.P26])
    } else {
        gpioLib.switchOff(ports: [.P26])
    }
}

func powerOff() {
    gpioLib.switchOff(ports: list)
}

let drop = Droplet()

drop.get { req in
    return try drop.view.make("welcome", [
        "message": drop.localization[req.lang, "welcome", "title"]
        ])
}

drop.get("cmd", ":id") { request in
    guard let cmdId = request.parameters["id"]?.int else {
        throw Abort.badRequest
    }

    switch(cmdId) {
    case Command.Zero:
        powerOff()
    case Command.One:
        yellow()
    case Command.Two:
        green()
    default:
        throw Abort.badRequest
    }

    return try JSON(node: [
        "version": "1.0.0",
        "command": "\(cmdId)",
        "yellow": "\(gpioLib.status(ports[.P20]))",
        "green": "\(gpioLib.status(ports[.P26]))"
        ])
}

drop.run()
