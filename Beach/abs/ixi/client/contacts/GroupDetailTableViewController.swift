

import UIKit
import SF_swift_framework

//: - View Controller to show group detail
class GroupDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate,UISearchDisplayDelegate {
    
    //MARK: - Outlets and variables
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var groupDetailTableView: UITableView!
    @IBOutlet weak var groupDetailView: UIView!
    @IBOutlet weak var contactsSearchBar: UISearchBar!
    @IBOutlet weak var groupName: UILabel!
    @IBOutlet weak var leaveGroupBtn: NSLayoutConstraint!
    var recieveUser:JID!
    var groupMembers:[ChatRoomMembers]! = []
    var activeSearch:Bool = false
    var searchArray:[ChatRoomMembers]! = []
    var userName:JID!
    var isAdmin = false
    
    //MARK:- View Controller Delegate method
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getUserData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.getGroupData()
        self.view.bringSubview(toFront: groupDetailView)
        contactsSearchBar.delegate = self
        contactsSearchBar.placeholder = "Search User ..."
        groupDetailTableView.tableFooterView = UIView(frame: .zero)
    }
    
    //MARK:- Get Data from Database
    func getUserData(){
        SFCoreDataManager.sharedInstance.getDataFromDataBase(entityName: "SFUserDetail",jid: "", success: { (users:[SFUserDetail]) in
            if !users.isEmpty {
                do {
                    try self.userName = JID(jid: users[0].userJid)
                } catch {
                }
            }
        },failure: { (str) in
            print(str)
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if self.activeSearch
        {
            return self.searchArray.count
        }
        return self.groupMembers.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactsTableViewCell", for: indexPath) as? ContactsTableViewCell
        if self.isAdmin{
            cell?.deleteBtn.isHidden = false
            cell?.deleteBtn.tag = indexPath.row
            cell?.deleteBtn.addTarget(self, action: #selector(self.deleteBtnAxn(_:)), for: .touchUpInside)
        }
        else{
            cell?.deleteBtn.isHidden = true
        }
        cell?.selectionStyle = .none
        if activeSearch {
            cell?.userSelectedImageView.isHidden = true
            cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
            cell?.userNameUILabel.text = searchArray[indexPath.row].name
            cell?.userType.text = searchArray[indexPath.row].affilation
            if (searchArray[indexPath.row].affilation?.elementsEqual("admin"))! || (searchArray[indexPath.row].affilation?.elementsEqual("owner"))!{
                cell?.deleteBtn.isHidden = true
            }
        }
        else {
            cell?.userNameUILabel.text = groupMembers[indexPath.row].name
            cell?.userSelectedImageView.isHidden = true
            cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
            cell?.userType.text = groupMembers[indexPath.row].affilation
            if (groupMembers[indexPath.row].affilation?.elementsEqual("admin"))! || (groupMembers[indexPath.row].affilation?.elementsEqual("owner"))!{
                cell?.deleteBtn.isHidden = true
            }
        }
        return cell!
    }
    
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    @objc public func deleteBtnAxn(_ sender:UIButton){
        do{
            if activeSearch{
                let corrId = UUID().uuidString
                _ = try Platform.getInstance().getUserManager().sendRemoveChatRoomMemberRequest(corrId: corrId, roomJID: self.recieveUser, userJID: JID(jid:searchArray[sender.tag].jid))
            }
            else{
                let corrId = UUID().uuidString
                _ = try Platform.getInstance().getUserManager().sendRemoveChatRoomMemberRequest(corrId: corrId, roomJID: self.recieveUser, userJID: JID(jid:groupMembers[sender.tag].jid))
            }
        }
        catch{
            print(error.localizedDescription)
        }
    }
    
    
    //MARK: - Get Data from Database
    func getGroupData(){
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "Rosters", jid: self.recieveUser.getBareJID(), success: { (users:[Rosters]) in
            if !users.isEmpty {
                self.groupImage.image =  #imageLiteral(resourceName: "group")
                
                ChatterUtil.setCirculerView(view: self.groupImage, radis: Float(self.groupImage.frame.size.height/2), borderColor: UIColor.clear, borderWidth: 0)
                self.groupImage.clipsToBounds = true
                self.groupName.text = users[0].name!
                self.groupMembers =  Array(users[0].members!) as! [ChatRoomMembers]
                
                self.navigationItem.title = users[0].name
                for member in self.groupMembers!{
                    if member.jid!.elementsEqual(self.userName.getBareJID()!){
                        if (member.affilation?.elementsEqual("admin"))! || (member.affilation?.elementsEqual("owner"))!{
                            self.isAdmin = true
                        }
                    }
                }
                self.groupDetailTableView.reloadData()
            }
            else {
                self.tabBarController?.tabBar.isHidden = true
            }
            
        },failure: { (String) in
            self.tabBarController?.tabBar.isHidden = true
        })
    }
    
    // MARK: -  Search Bar
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //self.activeSearch = true;
        
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.activeSearch = false;
        self.contactsSearchBar.resignFirstResponder()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.activeSearch = false;
        self.contactsSearchBar.resignFirstResponder()
    }
    
    
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if( searchText.isEmpty){
            self.activeSearch = false;
            self.contactsSearchBar.isSearchResultsButtonSelected = false
            self.contactsSearchBar.resignFirstResponder()
        } else {
            self.activeSearch = true;
            self.searchArray = self.groupMembers.filter({ (user) -> Bool in
                let tmp: NSString = user.name! as NSString
                let range = tmp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
                
                return range.location != NSNotFound
            })
        }
        self.groupDetailTableView.reloadData()
        
    }
    
    
    //MARK:- KeyBoard Hide
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.contactsSearchBar.resignFirstResponder()
        view.endEditing(true)
    }
    
    @IBAction func leaveGrpBtnAxn(_ sender: Any) {
        _ = Platform.getInstance().getUserManager().leaveChatRoom(roomJID: recieveUser)
    }
}
