import SF_swift_framework
import Foundation
import Darwin
import UIKit
class LoginViewController: UIViewController,UITextFieldDelegate {
    //IBOutlates
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet var password: UITextField!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var scrollView: UIScrollView!
    
    @IBAction func loginButtonAction(_ sender: Any) {
        loginBtn.isEnabled = false
        self.login()
    }
    
    //MARK : - View Controller Delegate Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        ChatterUtil.setCirculerView(view: usernameTextField, radis: Float(2), borderColor: UIColor.black, borderWidth: Float(1))
        ChatterUtil.setCirculerView(view: password, radis: Float(2), borderColor: UIColor.black, borderWidth: Float(1))
        errorLabel.isHidden = true
       self.addKeyBoardObserver()
        usernameTextField.delegate = self
        password.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        SDKLoader.shutdownSDK()
        SDKLoader.loadSDK(server: "188.166.251.121", port: 5222)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func login(){
        do{
            try Platform.getInstance().getUserManager().login(userName: usernameTextField.text!, password: password.text!,  domain:"alterbasics.com", success: { (String) in
                do {
                    _ = try Platform.getInstance().getUserManager().getFullRoster()
                    let corrId = UUID().uuidString
                    _ = Platform.getInstance().getUserManager().sendGetChatRoomsRequest(corrId: corrId)
                    Constants.appDelegate.registerForRemoteNotification(application: UIApplication.shared)
                    ChatterUtil.sendNotificationKey(pushNotificationService: PushNotificationService.FCM)
                }
                catch {
                    
                }
                DispatchQueue.main.async {
                    let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil);
                    let vc = (storyBoard.instantiateViewController(withIdentifier: "ChatterTabBarController") as? ChatterTabBarController)!
                    self.present(vc, animated: true, completion: nil)
                    self.loginBtn.isEnabled  = true
                    self.errorLabel.isHidden = true
                }
            }, failure: { (str) in
                DispatchQueue.main.async {
                    self.errorLabel.isHidden = false
                    self.errorLabel.text  = str
                    self.loginBtn.isEnabled  = true
                }
            })
        }
        catch {
            
        }
    }
    
    //MARK: - Method For handling Keyboard Action
    func addKeyBoardObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        self.scrollView.isScrollEnabled = true
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y == 0{
                view.frame.origin.y -= ((keyboardSize.height / 2) + 60 )
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.scrollView.isScrollEnabled = false
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.origin.y != 0{
                view.frame.origin.y += ((keyboardSize.height / 2) + 60 )
            }
        }
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
   
}

