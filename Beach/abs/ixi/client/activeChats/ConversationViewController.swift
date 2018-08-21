
import SF_swift_framework
import UIKit
import QuartzCore

public class ConversationViewController: UIViewController, UITableViewDelegate,ChatListener,PacketCollector, UITableViewDataSource,UISearchBarDelegate {
    
    //Variables
    @IBOutlet weak var chatsTableView: UITableView!
    @IBOutlet var chatsSearchBar: UISearchBar!
    var userName:[Conversation] = []
    var presence:[UserPresence] = []
    var activeSearch:Bool = false
    var searchArray:Array<Conversation> = []
    var refreshControl: UIRefreshControl!
    
    //MARK:-UIViewController delegate methods
    override public func viewDidLoad() {
        super.viewDidLoad()
        //Set delegate for packet collector
        self.setCollectorDelegate()
        self.setRefreshControlAndTapGesture()
        chatsTableView.tableFooterView = UIView(frame: .zero)
        setViewData()
        //Set Delegate for Search Bar
        chatsSearchBar.delegate = self
        chatsSearchBar.placeholder = "Search User ..."
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        SDKLoader.getMessageReceiver().addChatListener(chatListener: self)
        DispatchQueue.main.async {
            self.chatsSearchBar.isHidden = true
            self.getPresenceData()
            self.getChatData()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        SDKLoader.getMessageReceiver().removeChatListener(chatListener: self)
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK:- Adding UIRefreshControl
    public func setRefreshControlAndTapGesture(){
        
        let refresh = UIRefreshControl()
        self.refreshControl = refresh;
        self.chatsTableView.addSubview(self.refreshControl)
        self.refreshControl.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    
    func setViewData() -> Void {
        self.title = "Messaging"
        chatsTableView.delegate = self
        chatsTableView.dataSource = self
    }
    
    // MARK: - tableView
    // MARK: - Table view data source
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.activeSearch == true
        {
            return self.searchArray.count
        }
        return userName.count
        
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatsTableViewCell", for: indexPath) as? ChatsTableViewCell
        if self.activeSearch == true
        {
            cell?.userNameUILabel.text =  searchArray[indexPath.row].name
            cell?.latestMessageUILabel.text = searchArray[indexPath.row].last_chatline
            cell?.messageTimeStampUILabel.text =  (ChatterUtil.timeElapsedDateFormatter(timeToFormat: ChatterUtil.getDate(seconds: String(searchArray[indexPath.row].update_time)).timeIntervalSince1970))
            if Int(searchArray[indexPath.row].unread_chatline_count) != 0{
                cell?.unreadMessageCount.isHidden = false
                cell?.unreadMessageCount.text = String(Int(searchArray[indexPath.row].unread_chatline_count))
            }
            else {
                cell?.unreadMessageCount.isHidden = true
            }
            if searchArray[indexPath.row].is_group {
                cell?.chatterViewSelected.isHidden = true
                cell?.userImageImageView.image = #imageLiteral(resourceName: "group")
            }
            else {
                cell?.chatterViewSelected.isHidden = false
                cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
                if !self.checkPresence(conversationArray: self.searchArray, index: indexPath.row){
                    cell?.chatterViewSelected.backgroundColor = UIColor.lightGray
                }
            }
        }
        else {
            
            cell?.userNameUILabel.text =  userName[indexPath.row].name
            cell?.latestMessageUILabel.text = userName[indexPath.row].last_chatline
            cell?.messageTimeStampUILabel.text =  (ChatterUtil.timeElapsedDateFormatter(timeToFormat: ChatterUtil.getDate(seconds: String(userName[indexPath.row].update_time)).timeIntervalSince1970))
            if Int(userName[indexPath.row].unread_chatline_count) != 0{
                cell?.unreadMessageCount.isHidden = false
                
                cell?.unreadMessageCount.text = String(Int(userName[indexPath.row].unread_chatline_count))
            }
            else {
                cell?.unreadMessageCount.isHidden = true
            }
            if userName[indexPath.row].is_group {
                cell?.chatterViewSelected.isHidden = true
                cell?.userImageImageView.image = #imageLiteral(resourceName: "group")
            }
            else {
                cell?.chatterViewSelected.isHidden = false
                cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
                if !self.checkPresence(conversationArray: self.userName, index: indexPath.row){
                    cell?.chatterViewSelected.backgroundColor = UIColor.lightGray
                }
            }
        }
        cell?.messageReadStatusUIImageView.isHidden = true
        
        return cell!
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        
        let userChatViewController = self.storyboard?.instantiateViewController(withIdentifier: "UserChatViewController") as? UserChatViewController
        do { if activeSearch == true {
            userChatViewController?.recieveUser =  try JID(jid: searchArray[indexPath.row].peer_jid)
        }
        else {
            userChatViewController?.recieveUser =  try JID(jid: userName[indexPath.row].peer_jid)
            }
            
            self.navigationController?.pushViewController(userChatViewController!, animated: true)
        }
        catch {
            
        }
    }
    
    public func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, index in
            do{
                let myalert = try UIAlertController(title: "Delete Chat", message: "Are you want to delete chat of " + JID(jid: self.userName[editActionsForRowAt.row].peer_jid).getNode(), preferredStyle: UIAlertControllerStyle.alert)
                
                myalert.addAction(UIAlertAction(title: "Delete", style: .default) { (action:UIAlertAction!) in
                    print("Selected")
                    SFCoreDataManager.sharedInstance.deleteEntityFromDataBase(entityName: "Conversation", jid:self.userName[editActionsForRowAt.row].peer_jid, success: { (String) in
                        print(String!)
                        self.userName.remove(at: editActionsForRowAt.row)
                        self.chatsTableView.reloadData()
                    }, failure: { (String) in
                        print(String)
                    })
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
    
    //MARK:- get Data from Database
    //Get Presence Data
    func getPresenceData(){
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "UserPresence",jid: nil, success: { (presences:[UserPresence]) in
            self.presence = []
            for user in presences {
                self.presence.append(user)
                DispatchQueue.main.async {
                    self.chatsTableView.reloadData()
                }
            }
        }, failure: { (String) in
            print(String)
        })
    }
    
    //Get ActiveChat Data
    func getChatData() {
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "Conversation", jid: nil, success: { (activeChats:[Conversation]) in
            self.userName = activeChats
            self.userName = self.userName.sorted(by: { $0.update_time > $1.update_time })
            DispatchQueue.main.async {
                self.chatsTableView.reloadData()
            }
            
        }, failure: { (String) in
            print(String)
        })
    }
    
    //MARK:- Check user presence is Avialable or not 
    func checkPresence(conversationArray:Array<Conversation>,index:Int)->Bool{
        for user in presence{
            if user.jid?.lowercased() == conversationArray[index].peer_jid?.lowercased() {
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
        self.chatsSearchBar.resignFirstResponder()
        view.endEditing(true)
    }
    
    // MARK: -  Search Bar
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //        self.activeSearch = true;
        let indexPath = IndexPath(row: 0 , section: 0)
        self.chatsTableView.scrollToRow(at: indexPath, at: .top, animated: false)
        self.chatsTableView.setContentOffset(CGPoint(x:0,y:45), animated: false)
        self.chatsSearchBar.becomeFirstResponder()
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.activeSearch = false;
        self.chatsSearchBar.resignFirstResponder()
        chatsSearchBar.isHidden = true
        self.chatsTableView.reloadData()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.activeSearch = false;
        self.chatsSearchBar.resignFirstResponder()
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if( searchText.isEmpty){
            self.activeSearch = false;
            self.chatsSearchBar.isSearchResultsButtonSelected = false
            self.chatsSearchBar.resignFirstResponder()
        } else {
            self.activeSearch = true;
            self.searchArray = self.userName.filter({ (user) -> Bool in
                let tmp: NSString = user.name! as NSString
                let range = tmp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
                
                return range.location != NSNotFound
            })
        }
        self.chatsTableView.reloadData()
    }
    
    //MARK:- Navigate to user chat from Notification Click
    func navigateToUserChat(userJid:String) {
        do {
            let userChatViewController = self.storyboard?.instantiateViewController(withIdentifier: "UserChatViewController") as? UserChatViewController
            userChatViewController?.recieveUser =  try JID(jid: userJid )
            self.navigationController?.pushViewController(userChatViewController!, animated: true)
        }
        catch {
            
        }
    }
    
    //MARK:- Refresh View
    @objc func refresh(_ sender: Any) {
        // Code to refresh table view
        if self.chatsSearchBar.isHidden == false{
            self.chatsSearchBar.isHidden = true
        }else {
            self.chatsSearchBar.isHidden = false
        }
        self.chatsTableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    // MARK: - Collect peacket of Message Type
    func setCollectorDelegate(){
        Platform.getInstance().getPresenceManager().addPacketCollector(packetName:"Presence", collector: self)
    }
    
    public func collect(packet: Packet) {
         if packet.isKind(of: Presence.self){
            self.getPresenceData()
        }
    }
    
    public func collect(packets: [Packet]) {
        self.getPresenceData()
    }
    
    
    
    //MARK:- ChatListner Events
    //event when a message arrived
    public func onChatLine(packet: Message) {
            self.getChatData()
    }
    
    //event when a Ack arrived
    public func onServerAck(messageIds:[String:[String]]) {
        
    }
    
    //event when a Meassage Recieved Receipt arrived
    public func onCMDeliveryReceipt(messageId: String, contactJID: JID) {
        
    }
    //event when a Meassage Acknowldgement Receipt arrived
    public func onCMAcknowledgeReceipt(messageId: String, contactJID: JID) {
        
    }
    //event when a Meassage Displayed Receipt arrived
    public func onCMDisplayedReceipt(messageId: String, contactJID: JID) {
        
    }
    
    //event when Chat state notification Active arrive
    public func onActiveCSN(contactJID: JID) {
        
    }
    //event when Chat state notification Composing arrive
    public func onComposingCSN(contactJID: JID) {
        
    }
    
    //event when Chat state notification pause arrive
    public func onPausedCSN(contactJID: JID) {
        
    }
    
    //event when Chat state notification inactive arrive
    public func onInactiveCSN(contactJID: JID) {
        
    }
    
    //event when Chat state notification gone arrive
    public func onGoneCSN(contactJID: JID) {
        
    }
    
    
}
