

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
    var recieveUser:JID!
    var groupMembers:[ChatRoomMembers]! = []
    var activeSearch:Bool = false
    var searchArray:[ChatRoomMembers]! = []
    
    //MARK:- View Controller Delegate method
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.getGroupData()
        self.view.bringSubview(toFront: groupDetailView)
        contactsSearchBar.delegate = self
        contactsSearchBar.placeholder = "Search User ..."
        groupDetailTableView.tableFooterView = UIView(frame: .zero)
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
        if self.activeSearch == true
        {
            return self.searchArray.count
        }
        return self.groupMembers.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactsTableViewCell", for: indexPath) as? ContactsTableViewCell
        cell?.selectionStyle = .none
        if activeSearch == true {
            cell?.userSelectedImageView.isHidden = true
            cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
            cell?.userNameUILabel.text = searchArray[indexPath.row].name
        }
        else {
            cell?.userNameUILabel.text = groupMembers[indexPath.row].name
            cell?.userSelectedImageView.isHidden = true
            cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
        }
        return cell!
    }
    
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
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
                print(users[0].name! + "324u982`3421980912")
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
        
        if( searchText.characters.isEmpty){
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
    
}
