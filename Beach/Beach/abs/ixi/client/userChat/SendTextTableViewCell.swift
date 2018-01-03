import SF_swift_framework
import UIKit

//:-Cell to show send Text Message
class SendTextTableViewCell: UITableViewCell {

    @IBOutlet var sendTextView: UIView!
    @IBOutlet var sendTextSeenImage: UIImageView!
    @IBOutlet var sendTextDateLabel: UILabel!
    @IBOutlet var sendTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ChatterUtil.setCirculerView(view: sendTextView, radis: 5, borderColor: UIColor.clear, borderWidth: 0)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
