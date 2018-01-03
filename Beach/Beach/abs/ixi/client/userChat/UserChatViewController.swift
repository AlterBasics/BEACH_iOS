import SF_swift_framework
import UIKit

public class UserChatViewController: UIViewController , UITableViewDelegate, UITableViewDataSource,UITextViewDelegate, PacketCollector,UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
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
        
        Platform.getInstance().getChatManager().say(messageId: messageId, text: self.textView.text, to: recieveUser, isGroup: recieveUserRoster.is_group, success: {(str) in
            self.ack = false
            self.getChatData()
        },failure:{(str) in
            print(str)
        })
        
        
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
        self.setCollectorDelegate()
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
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        Constants.appDelegate.presentViewController = nil
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
        self.message = (message).sorted(by: { $0.create_time < $1.create_time})
        if message.count > 50 && !isRefresh {
            return 50
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
            if message[indexPath.row -  1].delivery_status{
                cell?.sendTextSeenImage.image = #imageLiteral(resourceName: "read_tick")
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
        CoreDataManager.sharedInstance.getUserInfoFromDataBase(entityName: "ChatStore", jid: self.recieveUser.getBareJID(), success: { (chats:[ChatStore]) in
            
            CoreDataManager.sharedInstance.getUserInfoFromDataBase(entityName: "Conversation", jid: self.recieveUser.getBareJID(), success: { (activeChats:[Conversation]) in
                if !activeChats.isEmpty {
                    self.chatNO = Int(activeChats[0].unread_chatline_count)
                }
                CoreDataManager.sharedInstance.updateUnreadCount(jid: self.recieveUser.getBareJID(), unread_chatline_count: 0)
            }, failure: { (String) in
                
            })
            DispatchQueue.main.async {
                self.message = chats
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
        if textView.text == "write message..."
        {
            textView.text = ""
        }
        textView.becomeFirstResponder()
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        
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
        CoreDataManager.sharedInstance.getUserInfoFromDataBase(entityName: "Rosters", jid: self.recieveUser.getBareJID(), success: { (users:[Rosters]) in
            if !users.isEmpty {
                self.userName.text = users[0].name
                self.userView.isHidden = true
                do {
                    if users[0].is_group{
                        self.userImage.image = #imageLiteral(resourceName: "group")
                        self.userDetailButton.isHidden = false
                        let infoButton = UIButton(type: .infoDark)
                        infoButton.addTarget(self, action: #selector(self.userDetaisAction(_:)), for: .touchUpInside)
                        let barButton = UIBarButtonItem()
                        barButton.customView = infoButton
                        self.navigationItem.setRightBarButton(barButton, animated: true)
                    }
                    else {
                        self.userImage.image = #imageLiteral(resourceName: "profile")
                        self.userDetailButton.isHidden = false
                        let infoButton = UIButton(type: .detailDisclosure)
                        infoButton.addTarget(self, action: #selector(self.reportAbuse), for: .touchUpInside)
                        let barButton = UIBarButtonItem()
                        barButton.customView = infoButton
                        self.navigationItem.setRightBarButton(barButton, animated: true)
                        
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
        CoreDataManager.sharedInstance.getUserInfoFromDataBase(entityName: "UserDetail", jid: "", success: { (users:[UserDetail]) in
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
    //MARK:- Packet Collector delegate method
    //Set delegate for packet collector
    func setCollectorDelegate(){
        SDKLoader.getMessageReceiver().addPacketCollector(packetName: "Message", collector: self)
        SDKLoader.getMessageReceiver().addPacketCollector(packetName: "AckPacket", collector: self)
    }
    
    //collect packet
    public func collect(packet: Packet) {
        if(packet.isKind(of: Message.self) ){
            let msg = packet as! Message
            let from = msg.getFrom()
            if Constants.appDelegate.presentViewController != nil && from?.getBareJID() == recieveUser.getBareJID(){
                self.ack = false
                self.getChatData()
            }
        }
        else if(packet.isKind(of: AckPacket.self) ){
            let ack:AckPacket =  packet as! AckPacket
            if ack.getMessageIds() != nil {
                let messageIds:[String] = ack.getMessageIds()!
                for id in messageIds {
                    let msgArray = self.message.filter({ (msg) -> Bool in
                        return msg.message_id!  == id
                    })
                    if !msgArray.isEmpty {
                        self.ack = true
                        self.getChatData()
                    }
                }
            }
        }
    }
    
    public func collect(packets: [Packet]) {
        
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

