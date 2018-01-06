import SF_swift_framework
import UIKit

public

class UserSettingTableViewController: UITableViewController {
    //MARK:-Varaibles
    var userName:JID!
    var sdkLoader:SDKLoader!
    
    //MARK:- View Controller Delegate Method
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Profile"
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.getData()
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source
    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    
    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell", for: indexPath) as! SettingTableViewCell
            cell.settingCellLabel.text = "Logout"
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserDetailTableViewCell", for: indexPath) as! UserDetailTableViewCell
        cell.userNameLabel.text = userName.getNode()
        cell.selectionStyle = .none
        return cell
    }
    
    override public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return UITableViewAutomaticDimension;//Choose your custom row height
    }
    
    
    override public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        if indexPath.row == 1 {
            UIApplication.shared.unregisterForRemoteNotifications()
            let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil);
            let vc = (storyBoard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController)!
            Constants.appDelegate.window!.rootViewController = vc
        }
    }
    
    //MARK:- Get Data from Database
    func getData(){
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "SFUserDetail", jid: "", success: { (users:[SFUserDetail]) in
            if !users.isEmpty {
                do {
                    try self.userName = JID(jid: users[0].userJid)
                    self.tableView.reloadData()
                } catch {
                }
            }
        },failure: { (str) in
            print(str)
        })
        
    }
    
}
