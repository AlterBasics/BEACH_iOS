import SF_swift_framework
import UIKit

//:- Cell to show recieve text message
class RecieveTextTableViewCell: UITableViewCell {
    
    @IBOutlet weak var memberName: UILabel!
    @IBOutlet var recieveTextView: UIView!
    @IBOutlet var recieveTextDateLabel: UILabel!
    @IBOutlet var recieveTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ChatterUtil.setCirculerView(view: recieveTextView, radis: 5, borderColor: UIColor.clear, borderWidth: 0)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
