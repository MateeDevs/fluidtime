@testable import FluidtimeCore
import ServiceManagement
import Testing

struct LoginItemStatusTests {
    @Test func `missing login item allows the first registration attempt`() {
        #expect(LaunchAtLoginStatus(serviceStatus: .notFound) == .disabled)
        #expect(!LaunchAtLoginStatus(serviceStatus: .notFound).isRegistered)
    }

    @Test func `system registration statuses preserve approval and enabled states`() {
        #expect(LaunchAtLoginStatus(serviceStatus: .notRegistered) == .disabled)
        #expect(LaunchAtLoginStatus(serviceStatus: .enabled) == .enabled)
        #expect(LaunchAtLoginStatus(serviceStatus: .requiresApproval) == .requiresApproval)
    }
}
