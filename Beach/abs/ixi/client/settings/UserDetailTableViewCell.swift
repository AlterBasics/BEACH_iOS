
import UIKit
//:- Cell for UserDetail
class UserDetailTableViewCell: UITableViewCell {

    @IBOutlet var userDesignationLabel: UILabel!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
