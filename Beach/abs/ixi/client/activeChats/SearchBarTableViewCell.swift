

import UIKit
//: Cell for Search Bar
class SearchBarTableViewCell: UITableViewCell,UISearchBarDelegate {
    
    var delegate:UIViewController!
    @IBOutlet weak var search: UISearchBar!
    
    //MARK:- Delegate Method
    override func awakeFromNib() {
        super.awakeFromNib()
        search.delegate = self
        search.placeholder = "Search User ..."
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    //MARK:- KeyBoard Hide
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.search.resignFirstResponder()
        delegate.view.endEditing(true)
    }
    
    
    
}
