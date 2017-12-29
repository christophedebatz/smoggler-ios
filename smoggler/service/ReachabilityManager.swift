import Foundation
import UIKit
import SystemConfiguration
import ReachabilitySwift
import CoreData

class ReachabilityManager: NSObject {
    
    static let shared = ReachabilityManager()
    var managedObjectContext: NSManagedObjectContext?
    
    override init() {
        self.managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    }
    
    var isNetworkAvailable : Bool {
        return reachabilityStatus != .notReachable
    }
    
    var reachabilityStatus: Reachability.NetworkStatus = isInternetAvailable() ? .reachableViaWWAN : .notReachable
    let reachability = Reachability()!
    
    @objc func reachabilityChanged(notification: Notification) {
        let reachability = notification.object as! Reachability
        reachabilityStatus = reachability.currentReachabilityStatus
        switch reachability.currentReachabilityStatus {
            case .notReachable: debugPrint("Network became unreachable")
        case .reachableViaWiFi: do {
                debugPrint("Network reachable through WiFi")
                let savedCigarettes: [Cigarette] = fetchCigarette()
                if savedCigarettes.count > 0 {
                    debugPrint("Sending about ", savedCigarettes.count, " cigarettes")
                    HttpService.sendCigarettes(cigarettes: savedCigarettes, completion: { (error: ApiError?) -> Void in
                        // hide loader
                        if error != nil {
                            // display error
                            print("error when sending cigarettes")
                        } else {
                            print("removing all local cigarettes")
                            let localService = LocalStorageService(managedObjectContext: self.managedObjectContext!)
                            localService.removeAllCigarettes()
                        }
                    })
                }
            }
        case .reachableViaWWAN: do {
                debugPrint("Network reachable through Cellular Data")
                let savedCigarettes: [Cigarette] = fetchCigarette()
                if savedCigarettes.count > 0 {
                    debugPrint("Sending about ", savedCigarettes.count, " cigarettes")
                    HttpService.sendCigarettes(cigarettes: savedCigarettes, completion: { (error: ApiError?) -> Void in
                        // hide loader
                        if error != nil {
                            // display error
                            print("error when sending cigarettes")
                        } else {
                            print("removing all local cigarettes")
                            let localService = LocalStorageService(managedObjectContext: self.managedObjectContext!)
                            localService.removeAllCigarettes()
                        }
                    })
                }
            }
        }
    }
    
    func fetchCigarette() -> [Cigarette] {
        let Cigarette = NSFetchRequest<Cigarette>(entityName: "Cigarette")
        
        do {
            return try (self.managedObjectContext?.fetch(Cigarette))! as [Cigarette]
        } catch {
            fatalError("Failed to fetch smoking moments: \(error)")
        }
    }
    
    func stopMonitoring() {
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: ReachabilityChangedNotification, object: reachability)
    }
    
    func startMonitoring() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ReachabilityManager.shared.reachabilityChanged(notification:)),
                                               name: ReachabilityChangedNotification,
                                               object: reachability)
        do{
            try reachability.startNotifier()
        } catch {
            debugPrint("Could not start reachability notifier")
        }
    }

    private static func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        
        return flags.contains(.reachable) && !flags.contains(.connectionRequired)
    }

}
