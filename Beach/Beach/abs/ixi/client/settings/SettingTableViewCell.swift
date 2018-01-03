
import UIKit
//:- Cell for App Setting
class SettingTableViewCell: UITableViewCell {
    
    @IBOutlet var settingImageLabel: UIImageView!
    @IBOutlet var settingCellLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
