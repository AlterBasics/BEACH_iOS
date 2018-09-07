
import UIKit
//:- Cell to show send image message
class SendImageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    @IBOutlet var sendImageSeenimageView: UIImageView!
    @IBOutlet var sendImageDateLabel: UILabel!
    @IBOutlet var sendImageLabel: UILabel!
    @IBOutlet var sendImageButton: UIButton!
    @IBOutlet var sendImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
