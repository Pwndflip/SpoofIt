import Foundation
import Network

enum NetworkPermissionHelper {
    /// Request local network permission by checking network path
    /// This triggers the iOS permission prompt for local network access
    static func requestLocalNetworkPermission() {
        let queue = DispatchQueue(label: "com.chrismack.locus.networkperm")
        let monitor = NWPathMonitor()
        
        // Start monitoring - this will trigger the permission request
        monitor.start(queue: queue)
        
        // Stop monitoring after a short delay since we only need the permission prompt
        queue.asyncAfter(deadline: .now() + 0.5) {
            monitor.cancel()
        }
    }
}
