
import UIKit

//:- Cell to show recieve image message
class RecieveImageTableViewCell: UITableViewCell {
    
    @IBOutlet var recieveImageView: UIView!
    @IBOutlet var recieveImageDateLabel: UILabel!
    @IBOutlet var recieveImageUserLabel: UILabel!
    @IBOutlet var recieveImageButton: UIButton!
    @IBOutlet var recieveImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ChatterUtil.setCirculerView(view: recieveImageView, radis: 5, borderColor: UIColor.clear, borderWidth: 0)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
