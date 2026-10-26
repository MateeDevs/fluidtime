import AppKit
import CoreServices
@testable import FluidtimeCore
import Testing

struct ApplicationLaunchTests {
    @Test func `login launch requires the login item marker on an open application event`() {
        #expect(!ApplicationLaunch.isLoginItem(nil))
        let event = NSAppleEventDescriptor(
            eventClass: kCoreEventClass, eventID: kAEOpenApplication,
            targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        #expect(!ApplicationLaunch.isLoginItem(event))
        event.setParam(NSAppleEventDescriptor(enumCode: keyAELaunchedAsServiceItem), forKeyword: keyAEPropData)
        #expect(!ApplicationLaunch.isLoginItem(event))
        event.setParam(NSAppleEventDescriptor(enumCode: keyAELaunchedAsLogInItem), forKeyword: keyAEPropData)
        #expect(ApplicationLaunch.isLoginItem(event))
        let reopen = NSAppleEventDescriptor(
            eventClass: kCoreEventClass, eventID: kAEReopenApplication,
            targetDescriptor: nil, returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        reopen.setParam(NSAppleEventDescriptor(enumCode: keyAELaunchedAsLogInItem), forKeyword: keyAEPropData)
        #expect(!ApplicationLaunch.isLoginItem(reopen))
    }
}
