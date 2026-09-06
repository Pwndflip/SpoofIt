import Darwin
import Foundation
import Network
import UIKit

enum LocalDevVPN {
    static let appStoreURL = URL(string: "https://apps.apple.com/us/app/localdevvpn/id6755608044")!
    static let detectURL = URL(string: "localdevvpn://")!

    /// Starts the tunnel, then returns to Locus via `locus://`.
    static let enableURL = URL(string: "localdevvpn://enable?scheme=locus")!

    static var isInstalled: Bool {
        UIApplication.shared.canOpenURL(detectURL)
    }

    /// LocalDevVPN puts the tunnel network on a `10.7.0.x` (or custom) utun when connected.
    /// Uses multiple detection methods for reliability on WiFi and cellular.
    static var isConnected: Bool {
        let target = TunnelConfig.targetIP
        
        // Method 1: Check interface addresses (primary method)
        let addresses = ipv4InterfaceAddresses()
        if addresses.contains(target) { return true }
        
        let parts = target.split(separator: ".")
        guard parts.count == 4 else { return false }
        let prefix = parts.dropLast().joined(separator: ".") + "."
        if addresses.contains(where: { $0.hasPrefix(prefix) }) { return true }
        
        // Method 2: Check all tunnel-like interfaces (fallback for WiFi issues)
        if checkTunnelInterfaces(prefix: prefix) { return true }
        
        // Method 3: Try to connect to the tunnel IP (as final check)
        return canReachTunnelIP(target)
    }

    static func openInstalled() {
        UIApplication.shared.open(enableURL)
    }

    static func openAppStore() {
        UIApplication.shared.open(appStoreURL)
    }

    /// Open LocalDevVPN to connect if installed; otherwise App Store.
    static func openOrInstall() {
        if isInstalled {
            openInstalled()
        } else {
            openAppStore()
        }
    }

    private static func ipv4InterfaceAddresses() -> [String] {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return [] }
        defer { freeifaddrs(ifaddr) }

        var results: [String] = []
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let current = ptr {
            let interface = current.pointee
            if interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let nameLen = socklen_t(MemoryLayout<sockaddr_in>.size)
                if getnameinfo(
                    interface.ifa_addr,
                    nameLen,
                    &host,
                    socklen_t(host.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                ) == 0 {
                    results.append(String(cString: host))
                }
            }
            ptr = interface.ifa_next
        }
        return results
    }
    
    /// Check all tunnel interfaces (utun*) to handle WiFi detection issues
    private static func checkTunnelInterfaces(prefix: String) -> Bool {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return false }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let current = ptr {
            let interface = current.pointee
            let interfaceName = String(cString: interface.ifa_name)
            
            // Check tunnel interfaces (utun0, utun1, etc.)
            if interfaceName.starts(with: "utun") && interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let nameLen = socklen_t(MemoryLayout<sockaddr_in>.size)
                if getnameinfo(
                    interface.ifa_addr,
                    nameLen,
                    &host,
                    socklen_t(host.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                ) == 0 {
                    let ipAddress = String(cString: host)
                    if ipAddress.hasPrefix(prefix) {
                        return true
                    }
                }
            }
            ptr = interface.ifa_next
        }
        return false
    }
    
    /// Attempt to reach the tunnel IP to verify connection
    private static func canReachTunnelIP(_ ip: String) -> Bool {
        let host = NWEndpoint.Host(ip)
        let endpoint = NWEndpoint.hostPort(host: host, port: 53)
        let connection = NWConnection(to: endpoint, using: .udp)
        
        var isReachable = false
        let semaphore = DispatchSemaphore(value: 0)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready, .preparing:
                isReachable = true
            case .failed, .cancelled:
                isReachable = false
            default:
                break
            }
            semaphore.signal()
        }
        
        connection.start(queue: .global())
        
        // Wait up to 100ms for connection state to become clear
        _ = semaphore.wait(timeout: .now() + 0.1)
        connection.cancel()
        
        return isReachable
    }
}
