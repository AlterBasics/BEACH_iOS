
import UIKit

//:- Cell to show recieve image message
class RecieveImageTableViewCell: UITableViewCell {
    
    @IBOutlet var recieveImageView: UIView!
    @IBOutlet var recieveImageDateLabel: UILabel!
    @IBOutlet var recieveImageUserLabel: UILabel!
    @IBOutlet var recieveImageButton: UIButton!
    @IBOutlet var recieveImage: UIImageView!
    
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
