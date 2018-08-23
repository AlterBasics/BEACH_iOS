import SF_swift_framework
import UIKit

//:- Cell for presenting Rosters Data
class ContactsTableViewCell: UITableViewCell {
    
    //MARK:- Outlet variable
    @IBOutlet weak var userImageImageView: UIImageView!
    @IBOutlet weak var userNameUILabel: UILabel!
    @IBOutlet weak var userSelectedImageView: UIImageView!
    
    //MARK:-Delegate Method
    override func awakeFromNib() {
        super.awakeFromNib()
        ChatterUtil.setCirculerView(view: userImageImageView, radis: Float(userImageImageView.frame.size.height/2), borderColor: UIColor.clear, borderWidth: 0)
        ChatterUtil.setCirculerView(view: userSelectedImageView, radis: Float(userSelectedImageView.frame.size.height/2), borderColor: UIColor.clear, borderWidth: 0)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    
    
}
