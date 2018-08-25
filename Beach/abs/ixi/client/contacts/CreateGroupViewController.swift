//
//  CreateGroupViewController.swift
//  Beach
//
//  Created by Shubham Garg on 22/08/18.
//  Copyright © 2018 AlterBasics. All rights reserved.
//

import UIKit
import SF_swift_framework

class CreateGroupViewController: UIViewController {
    
    @IBOutlet weak var selectedMembersLbl: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var groupSubjectLbl: UITextField!
    @IBOutlet weak var membersTableView: UITableView!
    var isGroupEditing: Bool = false
    var membersArray:[Rosters] = []
    var activeSearch:Bool = false
    var searchArray:Array<Rosters> = []
    var selectedArray:Array<Rosters> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.membersTableView.tableFooterView = UIView(frame: .zero)
        self.membersTableView.delegate = self
        self.membersTableView.dataSource = self
        groupSubjectLbl.delegate = self
        searchBar.delegate = self
        self.title = "Create Group"
        let barButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(self.createGroup))
        barButton.tintColor = .white
        self.navigationItem.rightBarButtonItem = barButton
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if isGroupEditing{
            
        }
        else{
            searchBar.isHidden = true
            selectedMembersLbl.isHidden = true
            self.getRosterData()
        }
    }
    
    func getRosterData(){
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "Rosters",jid: nil, success: { (rosters:[Rosters]) in
            let sortedArray = rosters.sorted {$0.name?.localizedCaseInsensitiveCompare($1.name!) == ComparisonResult.orderedAscending }
            self.membersArray = sortedArray.filter({ (roster) -> Bool in
                if roster.is_group {
                    return false
                }
                return true
            })
            DispatchQueue.main.async {
                if self.membersArray.count > 0 {
                    self.searchBar.isHidden = false
                }
                self.membersTableView.reloadData()
            }
            
        }, failure: { (String) in
            print(String)
        })
    }
    
    @objc public func createGroup(){
        if let name = groupSubjectLbl.text{
            Constants.appDelegate.addActivitiIndicaterView()
           let roomJid = Platform.getInstance().getUserManager().createRoom(roomName: name)
            if let jid = roomJid {
                do{
                for member in self.selectedArray{
                    let corrId = UUID().uuidString
                   _ = try Platform.getInstance().getUserManager().sendAddChatRoomMemberRequest(corrId: corrId, roomJID: jid, userJID: JID(jid:member.jid))
                }
                    Constants.appDelegate.hideActivitiIndicaterView()
                    self.navigationController?.popViewController(animated: true)
                }
                catch{
                    print(error.localizedDescription)
                }
            }
            
            
        }
        else{
            let alert = UIAlertController(title: nil, message: "Please enter a group name", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style:.default, handler: nil)
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK:- KeyBoard Hide
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.searchBar.resignFirstResponder()
        view.endEditing(true)
    }
    
}





extension CreateGroupViewController :UITableViewDelegate,UITableViewDataSource{
    
    // MARK: - Table view data source
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.activeSearch
        {
            return self.searchArray.count
        }
        
        return self.membersArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactsTableViewCell", for: indexPath) as? ContactsTableViewCell
        cell?.userSelectedImageView.isHidden  = true
        if activeSearch {
            cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
            cell?.userNameUILabel.text = searchArray[indexPath.row].name
            if selectedArray.contains(searchArray[indexPath.row]){
                cell?.accessoryType = .checkmark
            }
            else{
               cell?.accessoryType = .none
            }
        }
        else {
            cell?.userNameUILabel.text = membersArray[indexPath.row].name
            cell?.userImageImageView.image = #imageLiteral(resourceName: "profile")
            if selectedArray.contains(membersArray[indexPath.row]){
                cell?.accessoryType = .checkmark
            }
            else{
                cell?.accessoryType = .none
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
        if activeSearch{
            if !selectedArray.contains(searchArray[indexPath.row]){
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                selectedArray.append(searchArray[indexPath.row])
                selectedMembersLbl.isHidden = false
                selectedMembersLbl.text = selectedArray.compactMap({$0.name}).joined(separator: ",")
            }
            else{
                tableView.cellForRow(at: indexPath)?.accessoryType = .none
                selectedArray =  selectedArray.filter {$0 != searchArray[indexPath.row]}
                if selectedArray.count>0 {
                    selectedMembersLbl.isHidden = false
                    selectedMembersLbl.text = selectedArray.compactMap({$0.name}).joined(separator: ",")
                }
                else{
                    selectedMembersLbl.isHidden = true
                }
            }
        }
        else{
            if !selectedArray.contains(membersArray[indexPath.row]){
                tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
                selectedArray.append(membersArray[indexPath.row])
                selectedMembersLbl.isHidden = false
                selectedMembersLbl.text = selectedArray.compactMap({$0.name}).joined(separator: ",")
            }
            else{
                tableView.cellForRow(at: indexPath)?.accessoryType = .none
                selectedArray =  selectedArray.filter {$0 != membersArray[indexPath.row]}
                if selectedArray.count>0 {
                    selectedMembersLbl.isHidden = false
                    selectedMembersLbl.text = selectedArray.compactMap({$0.name}).joined(separator: ",")
                }
                else{
                    selectedMembersLbl.isHidden = true
                }
            }
        }
    }
}




// MARK: -  Search Bar Delegate Function
extension CreateGroupViewController : UISearchBarDelegate{
    
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //self.activeSearch = true;
        
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.activeSearch = false;
        self.searchBar.resignFirstResponder()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.activeSearch = false;
        self.searchBar.resignFirstResponder()
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if( searchText.isEmpty){
            self.activeSearch = false;
            self.searchBar.isSearchResultsButtonSelected = false
            self.searchBar.resignFirstResponder()
        } else {
            self.activeSearch = true;
            self.searchArray = self.membersArray.filter({ (user) -> Bool in
                let tmp: NSString = user.name! as NSString
                let range = tmp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
                return range.location != NSNotFound
            })
        }
        self.membersTableView.reloadData()
    }
    
}



//MARK:- Text Fields delegate function
extension CreateGroupViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.groupSubjectLbl.endEditing(true)
        self.view.endEditing(true)
        return true
    }
}
