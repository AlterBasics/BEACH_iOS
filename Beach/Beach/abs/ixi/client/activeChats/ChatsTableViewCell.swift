import SF_swift_framework
import UIKit
//: Cell for Active Chat
class ChatsTableViewCell: UITableViewCell {
    //Outlets Variable
    @IBOutlet var chatterViewSelected: UIImageView!
    @IBOutlet weak var userImageImageView: UIImageView!
    @IBOutlet weak var userNameUILabel: UILabel!
    @IBOutlet weak var messageReadStatusUIImageView: UIImageView!
    @IBOutlet weak var latestMessageUILabel: UILabel!
    @IBOutlet weak var unreadMessageCount: UILabel!
    @IBOutlet weak var messageTimeStampUILabel: UILabel!
    
    // MARK:- Cell function
    override func awakeFromNib() {
        super.awakeFromNib()
        unreadMessageCount.layer.masksToBounds =  true
        unreadMessageCount.layer.cornerRadius = 9
        ChatterUtil.setCirculerView(view: chatterViewSelected, radis: Float(chatterViewSelected.frame.size.height/2), borderColor: UIColor.clear, borderWidth: 0)
        ChatterUtil.setCirculerView(view: userImageImageView, radis: Float(userImageImageView.frame.size.height/2), borderColor: UIColor.clear, borderWidth: 0)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}
