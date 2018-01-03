
import UIKit

//:-Cell to show send pdf Message
class SendPdfTableViewCell: UITableViewCell {

    @IBOutlet var sendPdfSeenImage: UILabel!
    @IBOutlet var sendPdfDateLabel: UILabel!
    @IBOutlet var sendPdfLabel: UILabel!
    @IBOutlet var sendPdfImage: UIImageView!
    @IBOutlet var sendPdfView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
