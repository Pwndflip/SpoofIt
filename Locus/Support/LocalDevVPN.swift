import Darwin
import Foundation
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
    /// Uses interface enumeration to check for tunnel presence.
    static var isConnected: Bool {
        let target = TunnelConfig.targetIP
        
        // Method 1: Check if target IP is in active interfaces
        let addresses = ipv4InterfaceAddresses()
        if addresses.contains(target) { return true }
        
        // Method 2: Check if any address in same subnet (e.g., 10.7.0.x matches 10.7.0.1)
        let parts = target.split(separator: ".")
        guard parts.count == 4 else { return false }
        let prefix = parts.dropLast().joined(separator: ".") + "."
        if addresses.contains(where: { $0.hasPrefix(prefix) }) { return true }
        
        // Method 3: Check if any tunnel interface exists (utun*) - indicates LocalDevVPN is active
        return hasTunnelInterface()
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
    
    /// Check if any tunnel interface (utun*) exists
    /// This indicates LocalDevVPN is active, even if getnameinfo fails
    private static func hasTunnelInterface() -> Bool {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return false }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let current = ptr {
            let interfaceName = String(cString: current.pointee.ifa_name)
            // Any utun interface indicates LocalDevVPN tunnel is present
            if interfaceName.starts(with: "utun") {
                return true
            }
            ptr = current.pointee.ifa_next
        }
        return false
    }
}
