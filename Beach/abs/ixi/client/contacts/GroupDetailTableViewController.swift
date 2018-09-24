

import UIKit
import SF_swift_framework

//: - View Controller to show group detail
class GroupDetailViewController: UIViewController {
    
    //MARK: - Outlets and variables
    @IBOutlet weak var groupImage: UIImageView!
    @IBOutlet weak var groupDetailTableView: UITableView!
    @IBOutlet weak var groupDetailView: UIView!
    @IBOutlet weak var contactsSearchBar: UISearchBar!
    @IBOutlet weak var groupName: UITextField!
    @IBOutlet weak var leaveGroupBtn: NSLayoutConstraint!
    var recieveUser:JID!
    var groupMembers:[ChatRoomMembers]! = []
    var activeSearch:Bool = false
    var searchArray:[ChatRoomMembers]! = []
    var userName:JID!
    var isAdmin = false
    var group:Rosters!
    
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
        self.addHandlers()
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        self.removeHandlers()
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
    
    
    
    @objc public func deleteBtnAxn(_ sender:UIButton){
        do{
            if activeSearch{
                _ = try Platform.getInstance().getUserManager().sendRemoveChatRoomMemberRequest( roomJID: self.recieveUser, userJID: JID(jid:searchArray[sender.tag].jid))
            }
            else{
                _ = try Platform.getInstance().getUserManager().sendRemoveChatRoomMemberRequest( roomJID: self.recieveUser, userJID: JID(jid:groupMembers[sender.tag].jid))
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
                self.group = users[0]
                ChatterUtil.setCirculerView(view: self.groupImage, radis: Float(self.groupImage.frame.size.height/2), borderColor: UIColor.clear, borderWidth: 0)
                self.groupImage.clipsToBounds = true
                if users[0].room_subject != nil && users[0].room_subject?.replacingOccurrences(of: " ", with: "") !=  ""{
                    self.groupName.text = users[0].room_subject!
                    self.navigationItem.title = users[0].room_subject!
                }
                else{
                    self.groupName.text = users[0].name!
                    self.navigationItem.title = users[0].name
                }
                self.groupMembers =  Array(users[0].members!) as! [ChatRoomMembers]
                
                
                for member in self.groupMembers!{
                    if member.jid!.elementsEqual(self.userName.getBareJID()!){
                        if (member.affilation?.elementsEqual("admin"))! || (member.affilation?.elementsEqual("owner"))!{
                            self.isAdmin = true
                        }
                    }
                }
                if self.isAdmin{
                    self.groupName.isUserInteractionEnabled = false
                    let barButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.editGroup))
                    barButton.tintColor = .white
                    self.navigationItem.rightBarButtonItem = barButton
                }
                else{
                    self.groupName.isUserInteractionEnabled = true
                    let barButton = UIBarButtonItem(title: "Edit Subject", style: .plain, target: self, action: #selector(self.editGroupSubject))
                    barButton.tintColor = .white
                    self.navigationItem.rightBarButtonItem = barButton
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
    
    @objc public func editGroupSubject(){
        _ = Platform.getInstance().getUserManager().updateRoomSubject(roomJID: recieveUser, subject: groupName.text!)
    }
    
    @objc public func editGroup(){
        let createGroupVc = self.storyboard?.instantiateViewController(withIdentifier: "CreateGroupViewController") as? CreateGroupViewController
        createGroupVc?.isGroupEditing =  true
        createGroupVc?.group = self.group
        self.navigationController?.pushViewController(createGroupVc!, animated: true)
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

// MARK: - Table view data source
extension GroupDetailViewController :UITableViewDelegate, UITableViewDataSource{
    
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
}

// MARK: -  Search Bar
extension GroupDetailViewController :UISearchBarDelegate,UISearchDisplayDelegate{
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
}


extension GroupDetailViewController :EventHandler {
    
    func addHandlers(){
        Platform.addEventHandler(type: .CHAT_ROOM_DATA_UPDATE, handler: self)
        Platform.addEventHandler(type: .DATA_DELETE, handler: self)
    }
    
    func removeHandlers(){
        Platform.removeEventHandler(type: .CHAT_ROOM_DATA_UPDATE, handler: self)
        Platform.removeEventHandler(type: .DATA_DELETE, handler: self)
    }
    
    public func handle(e: Event) {
        if e.getType() == EventType.CHAT_ROOM_DATA_UPDATE{
            self.getGroupData()
        }
        if e.getType() == EventType.DATA_DELETE{
            self.getGroupData()
        }
    }
}
