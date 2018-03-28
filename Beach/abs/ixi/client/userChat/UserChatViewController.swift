import SF_swift_framework
import UIKit

public class UserChatViewController: UIViewController , UITableViewDelegate, UITableViewDataSource,UITextViewDelegate,ChatListener,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    
    //MARK: - Outlets & Variables
    @IBOutlet weak var userDetailButton: UIButton!
    @IBOutlet weak var userView: UIView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var attachView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var chatView: UIView!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var attachButton: UIButton!
    @IBOutlet var messagingChatTableView: UITableView!
    @IBOutlet var selectedRecipientCountLabel: UILabel!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var scrollView: UIView!
    @IBOutlet var textView: UITextView!
    var recieveUser:JID!
    var refreshControl: UIRefreshControl!
    var recieveUserRoster:Rosters!
    var chatNO = 1
    var keyBoard:CGFloat = 0
    var textViewHeight:CGFloat = 0
    var imagePicker = UIImagePickerController()
    var imageUrl:NSURL!
    var compressImage:UIImage!
    var imageInfo: [String : Any]!
    var ack = false
    var user:JID!
    var message:[ChatStore] = []
    var isRefresh = false
    var cSNStatus = false
    
    @IBAction func userDetaisAction(_ sender: Any) {
        let groupViewController = self.storyboard?.instantiateViewController(withIdentifier: "GroupDetailViewController") as? GroupDetailViewController
        groupViewController?.recieveUser =  self.recieveUser
        self.navigationController?.pushViewController(groupViewController!, animated: true)
    }
    
    @IBAction func cancelImageButtonAction(_ sender: Any) {
        self.chatView.isHidden = false
        self.attachView.isHidden = true
    }
    
    @IBAction func imageSendButtonAction(_ sender: Any) {
        if compressImage == nil {
            return
        }
        let messageId = UUID().uuidString
        let mediaId = UUID().uuidString
        let path = "/image.jpg"
        let filePath = documentsDirectory().appending(path)
        _ = saveImage(image: compressImage!, path: filePath)
        self.textView.text = ""
        _ =  Platform.getInstance().getChatManager().sendMediaMessage(messageId: messageId, mediaId: mediaId, toJID: recieveUser, isGroup: recieveUserRoster.is_group)
    }
    
    @IBAction func attachButtonAction(_ sender: Any) {
        
        let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Camera", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openCamera()
        })
        let saveAction = UIAlertAction(title: "Gallary", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openGallary()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(saveAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        //        messagingChatTableView.isHidden = true
        attachView.isHidden = false
        chatView.isHidden = true
        imageView.isHidden = false
        dismiss(animated: true, completion: nil)
        self.imageInfo = info
        
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.compressImage = ChatterUtil.compressedJpeg(image: image, compressionTimes: 1)
        imageView.image = compressImage
    }
    
    @IBAction func SendButtonAction(_ sender: Any) {
        if self.textView.text == nil || self.textView.text == "" {
            return
        }
        
        let messageId = UUID().uuidString
        if cSNStatus == false{
            Platform.getInstance().getChatManager().sendMarkableMessageWithCSN(messageId: messageId, text: self.textView.text, to: recieveUser, isGroup: recieveUserRoster.is_group, success: { (str) in
                self.ack = false
                self.cSNStatus = true
                self.getChatData()
            }, failure: { (str) in
                print(str)
            })
            
        }
        else{
            Platform.getInstance().getChatManager().say(messageId: messageId, text: self.textView.text, to: recieveUser, isGroup: recieveUserRoster.is_group, isMarkable:!recieveUserRoster.is_group, success: {(str) in
                self.ack = false
                self.getChatData()
            },failure:{(str) in
                print(str)
            })
            
        }
        self.textView.text = ""
        
    }
    
    
    //MARK:- Save Image locally
    func saveImage (image: UIImage, path: String ) -> Bool{
        //let imageData = UIImagePNGRepresentation(image)! as! NSMutableData // if you want to save as PNG
        let imageData = UIImageJPEGRepresentation(image, 0.8)! as! NSMutableData   // if you want to save as JPEG
        _ = FileManager.default.isWritableFile(atPath: path)
        let result = imageData.write(toFile:path,atomically:false)
        return result
    }
    
    //MARK:-  Get the documents Directory
    func documentsDirectory() -> String {
        let documentsFolderPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return documentsFolderPath
    }
    // Get path for a file in the directory
    
    //MARK:- Image Picker Method
    //Open gallery on Gallery button
    func openGallary()
    {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum
        present(imagePicker, animated: true, completion: nil)
    }
    
    //Open Camera on camera button
    func openCamera()
    {
        if(UIImagePickerController .isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)){
            imagePicker.allowsEditing = false
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.cameraCaptureMode = .photo
            present(imagePicker, animated: true, completion: nil)
        }else{
            let alert = UIAlertController(title: "Camera Not Found", message: "This device has no Camera", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style:.default, handler: nil)
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }
    }
    
    // Cancel image picker view
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK:- Get JID of reciever
    public func getJid()-> String {
        return self.recieveUser.getBareJID()
    }
    
    //MARK:- ViewController Delegate Method
    override public func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate=self
        messagingChatTableView.tableFooterView = UIView(frame: .zero)
        message = []
        attachButton.isHidden = false
        textView.delegate = self
        attachView.isHidden = true
        self.messagingChatTableView.bounces = true
        ChatterUtil.setCirculerView(view: textView, radis: 2, borderColor: UIColor.black, borderWidth: 0.5)
        self.addKeyBoardObserver()
        self.getUserDetail()
        //        self.setRefreshControlAndTapGesture()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        self.keyBoard = 0
        super.viewWillAppear(false)
        Constants.appDelegate.presentViewController = self
        self.setUser()
        self.isRefresh = false
        SDKLoader.getMessageReceiver().addChatListener(chatListener: self)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        Constants.appDelegate.presentViewController = nil
        SDKLoader.getMessageReceiver().removeChatListener(chatListener: self)
         _ = Platform.getInstance().getChatManager().sendInactiveCSN(to: recieveUser)
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK:- Mark this user as abuse
    @objc public func reportAbuse(){
        let alertView = UIAlertController(title: "Report Abuse", message: "You can block User", preferredStyle : .alert)
        
        let oKAction = UIAlertAction(title: "OK", style: .default, handler: { (alert) in
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (alert) in
        })
        alertView.addAction(oKAction)
        alertView.addAction(cancelAction)
        self.present(alertView, animated: true, completion: nil)
    }
    
    //MARK:- Table View Delegate Method
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        self.message = (message).sorted(by: { $0.create_time > $1.create_time})
        if message.count > 500 && !isRefresh {
            return 500
        }
        return message.count + 1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = UITableViewCell()
            return cell
        }
        if message[indexPath.row - 1].direction ==   Direction.SEND.rawValue
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SendTextTableViewCell", for: indexPath) as? SendTextTableViewCell
            cell?.selectionStyle = .none
            cell?.sendTextLabel.text = message[indexPath.row -  1].chatline
            if message[indexPath.row -  1].delivery_status == 1{
                cell?.sendTextSeenImage.image = #imageLiteral(resourceName: "read_tick")
            }
            else if (message[indexPath.row -  1].delivery_status == 2 || message[indexPath.row -  1].delivery_status == 3){
                cell?.sendTextSeenImage.image = #imageLiteral(resourceName: "recieved_tick")
            }
            else if message[indexPath.row -  1].delivery_status == 4{
                cell?.sendTextSeenImage.image = #imageLiteral(resourceName: "displayed_tick")
            }
            else {
                cell?.sendTextSeenImage.image = #imageLiteral(resourceName: "unread_tick")
            }
            cell?.sendTextDateLabel.text = ChatterUtil.dateFormatter(date: ChatterUtil.getDate(seconds: String(message[indexPath.row - 1].create_time))  as Date)
            return cell!
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "RecieveTextTableViewCell", for: indexPath) as? RecieveTextTableViewCell
            if recieveUserRoster.is_group {
                cell?.memberName.isHidden = false
                cell?.memberName.text = message[indexPath.row - 1].peer_res
            }
            else {
                cell?.memberName.isHidden = true
            }
            cell?.selectionStyle = .none
            cell?.recieveTextLabel.text =  message[indexPath.row - 1].chatline
            cell?.recieveTextDateLabel.text =  ChatterUtil.dateFormatter(date: ChatterUtil.getDate(seconds: String(message[indexPath.row - 1].create_time)) as Date)
            
            return cell!
        }
        
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 10
        }
        return UITableViewAutomaticDimension
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        self.bottomConstraint.constant = 0
        self.view.endEditing(true)
    }
    
    
    // MARK: - Get Chat Data from database
    
    public func getChatData(){
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "ChatStore", jid: self.recieveUser.getBareJID(), success: { (chats:[ChatStore]) in
            
            SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "Conversation", jid: self.recieveUser.getBareJID(), success: { (activeChats:[Conversation]) in
                if !activeChats.isEmpty {
                    self.chatNO = Int(activeChats[0].unread_chatline_count)
                }
                SFCoreDataManager.sharedInstance.updateUnreadCount(jid: self.recieveUser.getBareJID(), unread_chatline_count: 0)
            }, failure: { (String) in
                
            })
            print("message" )
            DispatchQueue.main.async {
                self.message = chats.sorted(by: { (chat1, chat2) -> Bool in
                    return chat1.create_time < chat2.create_time
                })
                let count = self.message.count
                if count > 200{
                self.message = Array(self.message[count-150 ..< count])
                }
                self.messagingChatTableView.reloadData()
                if !self.ack {
                    self.updateTableContentInset()
                    self.scrollToBottom()
                }
            }
        }) { (String) in
            print(String)
        }
    }
    
    //Mark:- Keyboard handel method
    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow")
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            keyBoard = keyboardSize.height - 10
            self.bottomConstraint.constant = keyboardSize.height + 3
            self.messagingChatTableView.reloadData()
            updateTableContentInset()
            self.scrollToBottom()
        }
    }
    
    func addKeyBoardObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        print("keyboardWillHide")
        keyBoard = 0
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            
            self.bottomConstraint.constant = 2
            self.messagingChatTableView.reloadData()
            updateTableContentInset()
            self.scrollToBottom()
        }
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.view.endEditing(true)
    }
    
    //MARK:- TextView Delegate method
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if cSNStatus{
         _ = Platform.getInstance().getChatManager().sendComposingCSN(to:recieveUser)
        }
        if textView.text == "write message..."
        {
            textView.text = ""
        }
        textView.becomeFirstResponder()
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        if cSNStatus{
        _ = Platform.getInstance().getChatManager().sendPausedCSN(to: recieveUser)
        }
        if textView.text == ""
        {
            textView.text = "write message..."
        }
        textView.resignFirstResponder()
        
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        self.textViewHeight = textView.frame.size.height
        if textView.frame.size.height  == 120 {
            textView.isScrollEnabled = true
            
        }
        else {
            textView.isScrollEnabled = false
        }
    }
    
    func textViewShouldReturn(_ textView: UITextView) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if cSNStatus{
            _ = Platform.getInstance().getChatManager().sendComposingCSN(to:recieveUser)
        }
        return true
    }
    
    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if cSNStatus{
            _ = Platform.getInstance().getChatManager().sendPausedCSN(to:recieveUser)
        }
        return true
    }
    
    func text(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        if cSNStatus{
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector( self.sendCSNStatus),
            object: textField)
        self.perform(
            #selector(self.sendCSNStatus),
            with: textField,
            afterDelay: 0.5)
    }
        return true
    }
    
    @objc public func sendCSNStatus(){
        _ = Platform.getInstance().getChatManager().sendPausedCSN(to: recieveUser)
    }
    
    func updateTableContentInset() {
        if message.count > 20 {
            let numRows = tableView(self.messagingChatTableView, numberOfRowsInSection: 0)
            var contentInsetTop = self.messagingChatTableView.bounds.size.height
            for i in 0..<numRows {
                contentInsetTop -= tableView(messagingChatTableView, heightForRowAt: IndexPath(item: i, section: 0))
                if contentInsetTop <= 0 {
                    contentInsetTop = 0
                }
            }
            messagingChatTableView.contentInset = UIEdgeInsetsMake(contentInsetTop, 0, 0, 0)
        }
    }
    
    //MARK:- set detail of user related to view
    func setUser(){
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "Rosters", jid: self.recieveUser.getBareJID(), success: { (users:[Rosters]) in
            if !users.isEmpty {
                self.userName.text = users[0].name
                self.userView.isHidden = true
                do {
                    if users[0].is_group{
                        self.userImage.image = #imageLiteral(resourceName: "group")
                        self.userDetailButton.isHidden = false
                        let image = UIImage(named: "info")
                        let renderedImage = image?.withRenderingMode(.alwaysOriginal)
                        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: renderedImage, style: .plain, target: self, action: #selector(self.userDetaisAction(_:)))
                    }
                    else {
                        self.userImage.image = #imageLiteral(resourceName: "profile")
                        self.userDetailButton.isHidden = false
                        let image = UIImage(named: "info")
                        let renderedImage = image?.withRenderingMode(.alwaysOriginal)
                        self.navigationItem.rightBarButtonItem =  UIBarButtonItem.init(image: renderedImage, style: .plain, target: self, action: #selector(self.reportAbuse))
                        
                    }
                }
                ChatterUtil.setCirculerView(view: self.userImage, radis: Float(self.userImage.frame.size.height/2), borderColor: UIColor.clear, borderWidth: 0)
                self.userImage.clipsToBounds = true
                print(users[0].name! + "324u982`3421980912")
                self.recieveUserRoster = users[0]
                self.title =  self.recieveUserRoster.name
                self.tabBarController?.tabBar.isHidden = true
                self.ack = false
                self.getChatData()
            }
            else{
                self.tabBarController?.tabBar.isHidden = true
            }
        },failure: { (String) in
            self.tabBarController?.tabBar.isHidden = true
        })
    }
    
    //Mark:- Get Logged User Detail
    func getUserDetail(){
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "SFUserDetail", jid: "", success: { (users:[SFUserDetail]) in
            if !users.isEmpty {
                do {
                    try self.user = JID(jid: users[0].userJid)
                    print(self.recieveUser.toString())
                } catch {
                }
            }
        },failure: { (str) in
            print(str)
        })
    }
    
    //Mark:- Scrolling view to show last message in Bottom
    func scrollToBottom(){
        if message.count > 5 {
            self.messagingChatTableView.setContentOffset(CGPoint(x:0,y:self.messagingChatTableView.contentSize.height - self.messagingChatTableView.frame.size.height + 50), animated: true)
        }
    }
    
    //MARK:-  UIRefreshControl
    //Adding refresh
    public func setRefreshControlAndTapGesture(){
        let refresh = UIRefreshControl()
        self.refreshControl = refresh;
        self.messagingChatTableView.addSubview(self.refreshControl)
        self.refreshControl.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    //refresh control Action
    @objc func refresh(_ sender: Any) {
        // Code to refresh table view
        self.isRefresh = true
        self.messagingChatTableView.reloadData()
        updateTableContentInset()
        self.scrollToBottom()
        refreshControl.endRefreshing()
        
    }
    
    //collect packet
    public func collect(packet: Packet) {
        
        //        else if(packet.isKind(of: AckPacket.self) ){
        //            let ack:AckPacket =  packet as! AckPacket
        //            if ack.getMessageIds() != nil {
        //                let messageIds:[String] = ack.getMessageIds()!
        //                for id in messageIds {
        //                    let msgArray = self.message.filter({ (msg) -> Bool in
        //                        if msg.message_id != nil {
        //                        return msg.message_id!  == id
        //                        }
        //                        return false
        //                    })
        //                    if !msgArray.isEmpty {
        //                        self.ack = true
        //                        self.getChatData()
        //                    }
        //                }
        //            }
        //        }
    }
    
    public func collect(packets: [Packet]) {
        
    }
    
    //MARK:- ChatListner Events
    //event when a message arrived
    public func onChatLine(packet: Message) {
        let from = packet.getFrom()
        if Constants.appDelegate.presentViewController != nil && from?.getBareJID() == recieveUser.getBareJID(){
            self.ack = false
            self.getChatData()
            //                messagingChatTableView.beginUpdates()
            //                messagingChatTableView.insertRows(at: [IndexPath(row: message.count, section: 0)], with: .automatic)
            //                messagingChatTableView.endUpdates()
        }
    }
    
    //event when a Ack arrived
    public func onServerAck(messageIds:[String:[String]]) {
        let msgIds = messageIds[recieveUser.getBareJID()]
        if msgIds != nil {
            self.ack = true
            self.getChatData()
        }
    }
    
    //event when a Meassage Recieved Receipt arrived
    public func onCMDeliveryReceipt(messageId: String, contactJID: JID) {
        if contactJID.getBareJID() == recieveUser.getBareJID(){
            getChatData()
        }
        
    }
    
    //event when a Meassage Acknowldgement Receipt arrived
    public func onCMAcknowledgeReceipt(messageId: String, contactJID: JID) {
        if contactJID.getBareJID() == recieveUser.getBareJID(){
            getChatData()
        }
    }
    
    //event when a Meassage Displayed Receipt arrived
    public func onCMDisplayedReceipt(messageId: String, contactJID: JID) {
        if contactJID.getBareJID() == recieveUser.getBareJID(){
            getChatData()
        }
    }
    
    //event when Chat state notification Active arrive
    public func onActiveCSN(contactJID: JID) {
        self.cSNStatus = true
    }
    //event when Chat state notification Composing arrive
    public func onComposingCSN(contactJID: JID) {
        self.title =  self.recieveUserRoster.name! + "\n is Typing..."
    }
    
    //event when Chat state notification pause arrive
    public func onPausedCSN(contactJID: JID) {
        self.title =  self.recieveUserRoster.name
    }
    
    //event when Chat state notification inactive arrive
    public func onInactiveCSN(contactJID: JID) {
        self.title =  self.recieveUserRoster.name
    }
    
    //event when Chat state notification gone arrive
    public func onGoneCSN(contactJID: JID) {
        self.title =  self.recieveUserRoster.name
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

