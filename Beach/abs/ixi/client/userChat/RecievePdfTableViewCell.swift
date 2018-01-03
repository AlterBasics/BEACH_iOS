
import UIKit

//:- Cell to show recieve pdf message
class RecievePdfTableViewCell: UITableViewCell {
    
    @IBOutlet var recievePdfView: UIView!
    @IBOutlet var recievePdfDateLabel: UILabel!
    @IBOutlet var recievePdfImage: UIImageView!
    @IBOutlet var recievePdfLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
