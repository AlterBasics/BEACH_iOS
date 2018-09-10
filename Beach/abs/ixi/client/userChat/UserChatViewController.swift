import SF_swift_framework
import UIKit

public class UserChatViewController: UIViewController {
    
    
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
    var user:JID!
    var message:[ChatStore] = []
    var isRefresh = false
    var cSNStatus = false
    
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
        if cSNStatus {
            _ = Platform.getInstance().getChatManager().sendInactiveCSN(to: recieveUser)
        }
    }
    
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
        do {
        Constants.appDelegate.addActivitiIndicaterView()
        let messageId = UUID().uuidString
        let path = "/image_\(messageId).jpg"
        let filePath =  directory().appending(path)
        let imageData = UIImageJPEGRepresentation(self.compressImage, 0.1)!
            print(imageData.count)// if you want to save as JPEG
//        let isWritable = FileManager.default.isWritableFile(atPath: filePath)
//            if isWritable{
            _ = try imageData.write(to:URL(fileURLWithPath:filePath),options:.atomic)
        self.textView.text = ""
            let destinationSize = CGSize.init(width: 50, height: compressImage.size.height*50/compressImage.size.width)
        UIGraphicsBeginImageContext(destinationSize)
        compressImage.draw(in: CGRect(x: 0, y: 0, width: destinationSize.width, height: destinationSize.height))
            let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
            let data = UIImageJPEGRepresentation(newImage!, 0.1)!
            print(data.count)
        let imageString = data.base64EncodedString()
        _ =  Platform.getInstance().getChatManager().sendMedia(conversationId:"", messageId: messageId, mediaId: messageId, filePath: path, contentType: ContentType(val: ContentType.IMAGE_JPEG), thumb: imageString, to: recieveUser, isGroup: recieveUserRoster.is_group,  success: { (str) in
            print(str)
            self.attachView.isHidden = true
            self.chatView.isHidden = false
            self.imageView.isHidden = true
            self.imageView.image = #imageLiteral(resourceName: "add")
            Constants.appDelegate.hideActivitiIndicaterView()
        }, failure: { (str) in
            print(str)
            
            Constants.appDelegate.hideActivitiIndicaterView()
        })
//            }
        }
        catch {
           Constants.appDelegate.hideActivitiIndicaterView()
        }
    }
    @IBAction func attachButtonAction(_ sender: Any) {
        
        let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openCamera()
        })
        let gallaryAction = UIAlertAction(title: "Gallary", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.openGallary()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        optionMenu.addAction(cameraAction)
        optionMenu.addAction(gallaryAction)
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    
    @IBAction func SendButtonAction(_ sender: Any) {
        if self.textView.text == nil || self.textView.text == "" || self.textView.text == "write message..." {
            return
        }
        self.textView.endEditing(true)
        let messageId = UUID().uuidString
        if cSNStatus == false && !recieveUserRoster.is_group{
            Platform.getInstance().getChatManager().sendMarkableMessageWithCSN(messageId: messageId, text: self.textView.text, to: recieveUser, isGroup: recieveUserRoster.is_group, success: { (str) in
                self.cSNStatus = true
                self.getChatData()
            }, failure: { (str) in
                print(str)
            })
        }
        else{
            Platform.getInstance().getChatManager().say(messageId: messageId, text: self.textView.text, to: recieveUser, isGroup: recieveUserRoster.is_group, isMarkable:!recieveUserRoster.is_group, success: {(str) in
                self.getChatData()
            },failure:{(str) in
                print(str)
            })
        }
        self.textView.text = ""
        
    }
    
    //MARK:-  Get the documents Directory
    func directory() -> String {
        let documentsFolderPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        return documentsFolderPath.appending("/sf")
    }
    // Get path for a file in the directory
    

    
    //MARK:- Get JID of reciever
    public func getJid()-> String {
        return self.recieveUser.getBareJID()
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
                    if !chat1.is_displayed && chat1.direction == Direction.RECEIVE.rawValue{
                        do {
                            
                            _ = try Platform.getInstance().getChatManager().sendMsgCMDisplayedReceipt(messageId: chat1.message_id!, to: JID(jid: chat1.peer_jid!))
                        }
                        catch{
                            
                        }
                    }
                    return chat1.create_time < chat2.create_time
                })
                self.messagingChatTableView.reloadData()
                self.updateTableContentInset()
                self.scrollToBottom()
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
    

    @objc public func sendCSNStatus(){
        _ = Platform.getInstance().getChatManager().sendPausedCSN(to: recieveUser)
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
                        self.sendButton.isUserInteractionEnabled = false
                        self.sendButton.isHidden = true
                        self.textView.isUserInteractionEnabled = false
                        self.textView.text = "you are not member of group"
                        for member in Array(users[0].members!) as! [ChatRoomMembers]{
                            if (member.jid?.elementsEqual(self.user.getBareJID()))!{
                                    self.sendButton.isUserInteractionEnabled = true
                                self.sendButton.isHidden = false
                                self.textView.isUserInteractionEnabled = true
                                self.textView.text = "write message..."
                                }
                        }
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

    
}

//MARK:- Table View Delegate Method
extension UserChatViewController:UITableViewDelegate, UITableViewDataSource{
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
            if message[indexPath.row - 1].chatline_type == ChatLineType.TEXT.rawValue{
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
            else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "SendImageTableViewCell", for: indexPath) as? SendImageTableViewCell
                cell?.selectionStyle = .none
                let imageURL = URL(fileURLWithPath: self.directory() + (message[indexPath.row - 1].media?.mediaPath!)!)
                let image = UIImage(contentsOfFile: imageURL.path)
                let width = UIScreen.main.bounds.size.width * 0.75
                let height = (width * (image?.size.height)!)/(image?.size.width)!
                var frame = cell?.imageView?.frame
                frame?.size.width = width
                frame?.size.height = height
                cell?.sendImage?.frame = frame!
                cell?.sendImage?.image = image
                cell?.leadingConstraint.constant = (UIScreen.main.bounds.size.width * 0.25) - 5
                if message[indexPath.row -  1].delivery_status == 1{
                    cell?.sendImageSeenimageView.image = #imageLiteral(resourceName: "read_tick")
                }
                else if (message[indexPath.row -  1].delivery_status == 2 || message[indexPath.row -  1].delivery_status == 3){
                    cell?.sendImageSeenimageView.image = #imageLiteral(resourceName: "recieved_tick")
                }
                else if message[indexPath.row -  1].delivery_status == 4{
                    cell?.sendImageSeenimageView.image = #imageLiteral(resourceName: "displayed_tick")
                }
                else {
                    cell?.sendImageSeenimageView.image = #imageLiteral(resourceName: "unread_tick")
                }
                cell?.sendImageDateLabel.text = ChatterUtil.dateFormatter(date: ChatterUtil.getDate(seconds: String(message[indexPath.row - 1].create_time))  as Date)
                return cell!
            }
        }
        else {
            if message[indexPath.row - 1].chatline_type == ChatLineType.TEXT.rawValue{
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
            else{
             let cell = tableView.dequeueReusableCell(withIdentifier: "RecieveImageTableViewCell", for: indexPath) as? RecieveImageTableViewCell
                let imageData = Data(base64Encoded: (message[indexPath.row - 1].media?.thumb!)!, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)
                cell?.recieveImageButton.setImage(UIImage(data: imageData!), for: .normal)
                return cell!
            }
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
        self.textView.endEditing(true)
    }
    
}

//MARK:- TextView Delegate method
extension UserChatViewController:UITextViewDelegate{
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
        if cSNStatus{
            _ = Platform.getInstance().getChatManager().sendInactiveCSN(to:recieveUser!)
        }
        
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
        if cSNStatus{
            _ = Platform.getInstance().getChatManager().sendGoneCSN(to: recieveUser!)
        }
        return false
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool{
        if cSNStatus{
            _ = Platform.getInstance().getChatManager().sendComposingCSN(to:recieveUser!)
            NSObject.cancelPreviousPerformRequests(
                withTarget: self,
                selector: #selector( self.sendCSNStatus),
                object: textView)
            self.perform(
                #selector(self.sendCSNStatus),
                with: textView,
                afterDelay: 5.0)
        }
        return true
    }
    
}

//MARK:- Image Picker Method
extension UserChatViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate{
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
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        attachView.isHidden = false
        chatView.isHidden = true
        imageView.isHidden = false
        dismiss(animated: true, completion: nil)
        self.imageInfo = info
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.compressImage = ChatterUtil.compressedJpeg(image: image, compressionTimes: 1)
        imageView.image = compressImage
    }
}

//MARK:- ChatListner Events
extension UserChatViewController : ChatListener{
    //event when a message arrived
    public func onChatLine(packet: Message) {
        let from = packet.getFrom()
        if Constants.appDelegate.presentViewController != nil && from?.getBareJID() == recieveUser.getBareJID(){
            self.getChatData()
        }
    }
    
    //event when a Ack arrived
    public func onServerAck(messageIds:[String:[String]]) {
        for (jid,msgs) in messageIds{
            if jid.elementsEqual(recieveUser.getBareJID()){
                for (no,msg) in self.message.enumerated(){
                    if msgs.contains(msg.message_id!){
                        if msg.direction  ==   Direction.SEND.rawValue {
                            DispatchQueue.main.async {
                                let indexPath = IndexPath(item: no+1, section: 0)
                                if let cell:SendTextTableViewCell = self.messagingChatTableView.cellForRow(at: indexPath) as? SendTextTableViewCell
                                {
                                    cell.sendTextSeenImage.image = #imageLiteral(resourceName: "read_tick")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //event when a Meassage Recieved Receipt arrived
    public func onCMDeliveryReceipt(messageId: String, contactJID: JID) {
        if contactJID.getBareJID() == recieveUser.getBareJID(){
            for (no,msg) in self.message.enumerated(){
                if msg.message_id!.elementsEqual(messageId){
                    if msg.direction  ==   Direction.SEND.rawValue {
                        DispatchQueue.main.async {
                            let indexPath = IndexPath(item: no+1, section: 0)
                            if let cell:SendTextTableViewCell = self.messagingChatTableView.cellForRow(at: indexPath) as? SendTextTableViewCell
                            {
                                cell.sendTextSeenImage.image = #imageLiteral(resourceName: "recieved_tick")
                            }
                        }
                    }
                }
            }
        }
    }
    
    //event when a Meassage Acknowldgement Receipt arrived
    public func onCMAcknowledgeReceipt(messageId: String, contactJID: JID) {
        if contactJID.getBareJID() == recieveUser.getBareJID(){
            for (no,msg) in self.message.enumerated(){
                if msg.message_id!.elementsEqual(messageId){
                    if msg.direction  ==   Direction.SEND.rawValue {
                        DispatchQueue.main.async {
                            let indexPath = IndexPath(item: no+1, section: 0)
                            if let cell:SendTextTableViewCell = self.messagingChatTableView.cellForRow(at: indexPath) as? SendTextTableViewCell
                            {
                                cell.sendTextSeenImage.image = #imageLiteral(resourceName: "recieved_tick")
                            }
                        }
                    }
                }
            }
        }
    }
    
    //event when a Meassage Displayed Receipt arrived
    public func onCMDisplayedReceipt(messageId: String, contactJID: JID) {
        if contactJID.getBareJID() == recieveUser.getBareJID(){
            for (no,msg) in self.message.enumerated(){
                if msg.message_id!.elementsEqual(messageId){
                    if msg.direction  ==   Direction.SEND.rawValue {
                        DispatchQueue.main.async {
                            let indexPath = IndexPath(item: no+1, section: 0)
                            if let cell:SendTextTableViewCell = self.messagingChatTableView.cellForRow(at: indexPath) as? SendTextTableViewCell {
                                cell.sendTextSeenImage.image = #imageLiteral(resourceName: "displayed_tick")
                            }
                        }
                    }
                }
            }
        }
    }
    
    //event when Chat state notification Active arrive
    public func onActiveCSN(contactJID: JID) {
        self.cSNStatus = true
    }
    //event when Chat state notification Composing arrive
    public func onComposingCSN(contactJID: JID) {
        DispatchQueue.main.async {
            self.title =  self.recieveUserRoster.name! + " is typing..."
        }
    }
    
    //event when Chat state notification pause arrive
    public func onPausedCSN(contactJID: JID) {
        DispatchQueue.main.async {
            self.title =  self.recieveUserRoster.name
        }
    }
    
    //event when Chat state notification inactive arrive
    public func onInactiveCSN(contactJID: JID) {
        DispatchQueue.main.async {
            self.title =  self.recieveUserRoster.name
        }
    }
    
    //event when Chat state notification gone arrive
    public func onGoneCSN(contactJID: JID) {
        DispatchQueue.main.async {
            self.title =  self.recieveUserRoster.name
        }
    }
}
