import Foundation
import Network

enum NetworkPermissionHelper {
    /// Request local network permission by creating a local network connection attempt
    /// This triggers the iOS permission prompt for local network access
    static func requestLocalNetworkPermission() {
        // Try creating a connection to trigger permission prompt
        DispatchQueue.main.async {
            let parameters = NWParameters.tcp
            let endpoint = NWEndpoint.hostPort(host: "localhost", port: 5900)
            let connection = NWConnection(to: endpoint, using: parameters)
            
            connection.stateUpdateHandler = { _ in }
            connection.start(queue: .global())
            
            // Stop immediately - we just need to trigger the permission prompt
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                connection.cancel()
            }
        }
    }
}
