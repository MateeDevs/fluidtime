import AppKit
import CoreServices

/// Read the event during applicationDidFinishLaunching, before dispatching startup effects.
enum ApplicationLaunch {
    static func isLoginItem(_ event: NSAppleEventDescriptor?) -> Bool {
        event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}
