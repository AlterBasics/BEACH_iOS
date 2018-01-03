import SF_swift_framework
import UIKit

public class ContactsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate ,PacketCollector,UISearchDisplayDelegate{
    //MARK:- Outlet And Variables
    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var contactsSearchBar: UISearchBar!
    @IBOutlet weak var selectedRecipientLabel: UILabel!
    var refreshControl: UIRefreshControl!
    var userName:[Rosters] = []
    var presence:[UserPresence] = []
    var activeSearch:Bool = false
    var searchArray:Array<Rosters> = []
    
    //MARK: - Delegate Method for view controller
    override public func viewDidLoad() {
        super.viewDidLoad()
        Platform.getInstance().getPresenceManager().addPacketCollector(packetName:"Presence", collector: self)
        contactsTableView.tableFooterView = UIView(frame: .zero)
        setViewData()
        self.setRefreshControlAndTapGesture()
        contactsSearchBar.delegate = self
        contactsSearchBar.placeholder = "Search User ..."
        
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        contactsSearchBar.isHidden = true
        self.getPresenceData()
        self.getRosterData()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        
    }
    
    func setViewData() {
        self.title = "Contacts"
    }
    
    
    public func addUserDetails(name:String) {
        //        userName.append(name)
        self.contactsTableView.reloadData()
    }
    
    
    
    //MARK:- Packet Collector Delegate Method
    public func collect(packet: Packet) {
        if packet.isKind(of: Presence.self){
            self.getPresenceData()
        }
        else if packet.isKind(of: Roster.self) {
            self.getRosterData()
        }
    }
    
    public func collect(packets: [Packet]) {
        self.getPresenceData()
        self.getRosterData()
    }
    
    // MARK: - Table view data source
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.activeSearch == true
        {
            selectedRecipientLabel.text = String(searchArray.count) + " Contacts"
            return self.searchArray.count
        }
        selectedRecipientLabel.text = String(userName.count) + " Contacts"
        return userName.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactsTableViewCell", for: indexPath) as? ContactsTableViewCell
        if activeSearch == true {
            if searchArray[indexPath.row].is_group {
                cell?.userSelectedImageView.isHidden = true
                cell?.userImageImageView.image = #imageLiteral(resourceName: "group")
            }
            else{
                cell?.userSelectedImageView.isHidden = false
                cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
                if !self.checkPresence(conversationArray: self.searchArray, index: indexPath.row){
                    cell?.userSelectedImageView.backgroundColor = UIColor.lightGray
                }
            }
            cell?.userNameUILabel.text = searchArray[indexPath.row].name
        }
        else {
            cell?.userNameUILabel.text = userName[indexPath.row].name
            if userName[indexPath.row].is_group {
                cell?.userSelectedImageView.isHidden = true
                cell?.userImageImageView.image = #imageLiteral(resourceName: "group")
            }
            else{
                cell?.userSelectedImageView.isHidden = false
                cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
                if !self.checkPresence(conversationArray: self.userName, index: indexPath.row){
                    cell?.userSelectedImageView.backgroundColor = UIColor.lightGray
                }
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
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        let userChatViewController = self.storyboard?.instantiateViewController(withIdentifier: "UserChatViewController") as? UserChatViewController
        do {
            print(userName[indexPath.row].jid!)
            if activeSearch == true {
                userChatViewController?.recieveUser =  try JID(jid: searchArray[indexPath.row].jid)
            }
            else {
                userChatViewController?.recieveUser =  try JID(jid: userName[indexPath.row].jid)
            }
            
            self.navigationController?.pushViewController(userChatViewController!, animated: true)
        }
        catch {
        }
    }
    
    public func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            
            do{
                let myalert = try UIAlertController(title: "Delete Contact", message: "Are you want to delete Contact of " + JID(jid: self.userName[editActionsForRowAt.row].jid).getNode(), preferredStyle: UIAlertControllerStyle.alert)
                
                myalert.addAction(UIAlertAction(title: "Delete", style: .default) { (action:UIAlertAction!) in
                    do {
                        print("Selected")
                        _ = try Platform.getInstance().getUserManager().removeRosterMember(jid: JID(jid: self.userName[editActionsForRowAt.row].jid), contactName: self.userName[editActionsForRowAt.row].name!, success: {(succ) in
                            self.userName.remove(at: editActionsForRowAt.row)
                            self.contactsTableView.reloadData()
                        }, failure: {(fail) in
                            print(fail)
                        } )
                        
                    }
                    catch{
                    }
                })
                myalert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction!) in
                    return
                })
                self.present(myalert, animated: true)
            }
            catch {
            }
        }
        delete.backgroundColor = .red
        let mute = UITableViewRowAction(style: .normal, title: "Mute") { action, index in
            print("Mute button tapped")
        }
        mute.backgroundColor = .orange
        return [ delete, mute]
    }
    
    
    func getRosterData(){
        CoreDataManager.sharedInstance.getUserInfoFromDataBase(entityName: "Rosters",jid: nil, success: { (rosters:[Rosters]) in
            let sortedArray = rosters.sorted { $0.name?.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending }
            self.userName = sortedArray
            DispatchQueue.main.async {
                self.contactsTableView.reloadData()
            }
            
        }, failure: { (String) in
            print(String)
        })
    }
    
    func getPresenceData() {
        CoreDataManager.sharedInstance.getUserInfoFromDataBase(entityName: "UserPresence",jid: nil, success: { (presences:[UserPresence]) in
            self.presence = presences
            DispatchQueue.main.async {
                self.contactsTableView.reloadData()
            }
        }, failure: { (String) in
            print(String)
        })
    }
    
    //MARK:- Check user presence is Avialable or not
    func checkPresence(conversationArray:Array<Rosters>,index:Int)->Bool{
        for user in presence{
            if user.jid?.lowercased() == conversationArray[index].jid?.lowercased() {
                if user.presence?.uppercased() == PresenceType.AVAILABLE.uppercased() {
                    return true
                }
            }
        }
        return false
    }
    
    //MARK:- KeyBoard Hide
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.contactsSearchBar.resignFirstResponder()
        view.endEditing(true)
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
        
        if( searchText.characters.isEmpty){
            self.activeSearch = false;
            self.contactsSearchBar.isSearchResultsButtonSelected = false
            self.contactsSearchBar.resignFirstResponder()
        } else {
            self.activeSearch = true;
            self.searchArray = self.userName.filter({ (user) -> Bool in
                let tmp: NSString = user.name! as NSString
                let range = tmp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
                return range.location != NSNotFound
            })
        }
        self.contactsTableView.reloadData()
    }
    
    
    //MARK:-  UIRefreshControl
    //Adding refresh
    public func setRefreshControlAndTapGesture(){
        let refresh = UIRefreshControl()
        self.refreshControl = refresh;
        self.contactsTableView.addSubview(self.refreshControl)
        self.refreshControl.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    // Refresh Action
    @objc func refresh(_ sender: Any) {
        // Code to refresh table view
        refreshControl.endRefreshing()
        if self.contactsSearchBar.isHidden == false{
            self.contactsSearchBar.isHidden = true
            self.contactsTableView.reloadData() 
        }else {
            self.contactsSearchBar.isHidden = false
            self.contactsTableView.reloadData()
        }
        
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
