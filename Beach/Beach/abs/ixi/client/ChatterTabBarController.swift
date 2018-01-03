
import UIKit
//Tab bar view controller to custmize Tab
class ChatterTabBarController: UITabBarController {
    //Delegate Methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func  tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.tag == 0 {
            
            let tabbar:UITabBarController = self as UITabBarController
            tabbar.selectedIndex = 0
            let navC = tabbar.viewControllers![0] as! UINavigationController
            navC.popToRootViewController(animated: false)
        }
        if item.tag == 1 {
            
            let tabbar:UITabBarController = self as UITabBarController
            tabbar.selectedIndex = 1
            let navC = tabbar.viewControllers![1] as! UINavigationController
            navC.popToRootViewController(animated: false)
        }
        
        print("selected item is \(item)")
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
