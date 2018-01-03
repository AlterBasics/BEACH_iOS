
import Foundation
import Reachability
import SF_swift_framework
//:- Manage internet Reachability
class ReachabilityManager: NSObject {
    //MARK: - Properities
    var reachability: Reachability? = Reachability()!
    let reachabilityChangedNotification = "ReachabilityChangedNotification"
    //MARK: - Manager
    static var sharedManager = ReachabilityManager ()
    
    //MARK: - Lifecycle
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(ReachabilityManager.reachabilityChanged), name: NSNotification.Name(rawValue: reachabilityChangedNotification), object: reachability)
        do {
            
            try self.reachability?.startNotifier()
        } catch {
            print("Reachable failed")
            return
        }
    }
    
    //MARK:- Rechability Chaned action
    @objc func reachabilityChanged(notification: NSNotification) {
        let reachability = notification.object as! Reachability
        print("reachability change")
        switch reachability.connection {
        case .wifi:
            print("Reachable via WiFi")
             ConnectionManager.getInstance().setNetworkConnectivity(networkConnectivity: true)
            break
        case .cellular:
            print("Reachable via Cellular")
             ConnectionManager.getInstance().setNetworkConnectivity(networkConnectivity: true)
            break
        case .none:
            print("Network not reachable")
            ConnectionManager.getInstance().setNetworkConnectivity(networkConnectivity: false)
        }
    }
    
}
