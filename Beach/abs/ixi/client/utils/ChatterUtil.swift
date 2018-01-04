

import Foundation
import  UIKit
import SF_swift_framework
/*
 # Utility for Chat
 */
public class ChatterUtil {
    // MARK: - Variables
    static var indicator:Bool = false
    static var activityindicater:UIActivityIndicatorView! = nil
    static var activityindicaterView:UIView! = nil
    
    // MARK: - Make view Circular
    public static func setCirculerView (view:AnyObject, radis:Float, borderColor:UIColor,borderWidth:Float) -> Void {
        view.layer.cornerRadius = CGFloat(radis)
        view.layer.borderWidth = CGFloat(borderWidth)
        view.layer.borderColor = borderColor.cgColor
    }
    
    // MARK: -  Date Formatterd
    //time Elapsed date frmatter
    public static func timeElapsedDateFormatter(timeToFormat : Double) -> String {
        
        var timeInterval : String = "Just now";
        
        let currentTime = NSDate();
        let currentTimeMs : Double = currentTime.timeIntervalSinceReferenceDate;
        
        let timeIntervalElapsed : Double = (currentTimeMs - timeToFormat) * 1000.0;
        var timeUnit : String = "ago"
        if(timeIntervalElapsed < 0) {
            
            timeUnit = "ahead"
        }
        
        if(timeIntervalElapsed != 0) {
            
            var period : String = "ms";
            
            var timeIntervalDifference = abs(timeIntervalElapsed);
            if(timeIntervalDifference > 1000 && period == self.TimeIntervals.MS.rawValue) {
                
                period = self.TimeIntervals.Seconds.rawValue;
                timeIntervalDifference = timeIntervalDifference / 1000;
            }
            
            if(timeIntervalDifference > 60 && period == self.TimeIntervals.Seconds.rawValue) {
                
                period = self.TimeIntervals.Minutes.rawValue;
                timeIntervalDifference = timeIntervalDifference / 60;
            }
            
            if(timeIntervalDifference > 60 && period == self.TimeIntervals.Minutes.rawValue) {
                
                period = self.TimeIntervals.Hours.rawValue;
                timeIntervalDifference = timeIntervalDifference / 60;
            }
            
            var _ : Double = 0.0;
            
            if(timeIntervalDifference > 12 && period == self.TimeIntervals.Hours.rawValue) {
                
                let date = NSDate(timeIntervalSince1970: timeToFormat)
                let dateFormatter = DateFormatter()
                
                let calendar = Calendar.current
                
                let year = calendar.component(.year, from: date as Date)
                
                let currentyear = calendar.component(.year, from: NSDate() as Date)
                
                if year == currentyear
                {
                    dateFormatter.dateFormat = "MMMM d"
                }else
                {
                    dateFormatter.dateFormat = "MMMM d, yyyy"
                }
                // Returns date formatted as 12 hour time.
                return dateFormatter.string(from: date as Date)
            }
            
            if(timeIntervalDifference > 10 && period == self.TimeIntervals.Years.rawValue) {
                period = self.TimeIntervals.Decades.rawValue;
                timeIntervalDifference = timeIntervalDifference / 10;
            }
            
            if(timeIntervalDifference > 10 && period == self.TimeIntervals.Decades.rawValue) {
                
                period = self.TimeIntervals.Ages.rawValue;
                timeIntervalDifference = timeIntervalDifference / 10;
            }
            
            if(timeIntervalDifference < 1) {
                
                timeIntervalDifference = 1;
            }
            
            
            let timeIntervalInPeriod : String = String.localizedStringWithFormat("%0.0f", floor(timeIntervalDifference));
            
            if(timeIntervalInPeriod == "1" && period != self.TimeIntervals.MS.rawValue && period != self.TimeIntervals.Ages.rawValue) {
                
                period = String(period[ ..<period.index(before: period.endIndex)])
            }
            
            if(period == self.TimeIntervals.MS.rawValue) {
                
                timeInterval = "Just now";
            }
            else {
                
                if(period != self.TimeIntervals.Ages.rawValue) {
                    
                    timeInterval = timeIntervalInPeriod + " " + period + " " + timeUnit;
                }
                else {
                    
                    timeInterval = period + " " + timeUnit;
                }
            }
        }
        
        return timeInterval;
    }
    
    //Formate date
    public static func dateFormatter(date: Date)-> String
    {
        
        let formatter = DateFormatter()
        
        //formatter.dateFormat = "MMM dd, yyyy '|' hh:mm a"
        formatter.dateFormat = "MMM dd hh:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        
        let result = formatter.string(from: date)
        return result
    }
    
    // MARK: - get Date
    
    public static func getDate(seconds:String) ->NSDate
    {
        let dateString = seconds
        let timeinterval : TimeInterval = (dateString as NSString).doubleValue
        let date = NSDate(timeIntervalSinceReferenceDate: timeinterval)
        return date
    }
    
    // MARK: - Time Interval
    public enum TimeIntervals : String {
        
        case MS = "ms"
        case Seconds = "seconds"
        case Minutes = "minutes"
        case Hours = "hours"
        case Days = "days"
        case Weeks = "weeks"
        case Months = "months"
        case Years = "years"
        case Decades = "decades"
        case Ages = "ages"
    }

    // MARK:- Set Navigation bar color and image etc
    public static func setNavigationBar() -> Void {
        //  UITabBar.appearance().tintColor = UIColor(red:199/255.0, green:199/255.0, blue:199/255.0, alpha:1.0)
        UITabBar.appearance().barTintColor = UIColor(red:247/255.0, green:248/255.0, blue:249/255.0, alpha:1.0)
        UINavigationBar.appearance().tintColor = UIColor(red:59.0/255.0, green:89.0/255.0, blue:136.0/255.0, alpha:1.0)
        UINavigationBar.appearance().barTintColor = UIColor(red:59.0/255.0, green:89.0/255.0, blue:136.0/255.0, alpha:1.0)
        let titleDict: NSDictionary = [NSAttributedStringKey.foregroundColor: UIColor.white,NSAttributedStringKey.font: UIFont.systemFont(ofSize: CGFloat(20.0), weight: UIFont.Weight.light)]
        UINavigationBar.appearance().titleTextAttributes = titleDict as? [NSAttributedStringKey : Any]
        
        UINavigationBar.appearance().isTranslucent = false;
        let stringFlowBundle = Bundle(identifier: "abs.ixi.StringFlow")
        let image = UIImage(named: "back", in: stringFlowBundle, compatibleWith: nil)
        
        let backArrowImage = image
        let renderedImage = backArrowImage?.withRenderingMode(.alwaysOriginal)
        UINavigationBar.appearance().backIndicatorImage = renderedImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = renderedImage
        
    }
    
    // MARK:- Compress images
    public static func compressedJpeg(image: UIImage?, compressionTimes: Int) -> UIImage? {
        
        var compressedImageData: NSData?
        
        if var imageCompressed = image {
            
            for _ in 0  ..< compressionTimes {
                
                compressedImageData = UIImageJPEGRepresentation(imageCompressed, 0.1)! as NSData
                imageCompressed = UIImage(data: compressedImageData! as Data)!
            }
            
            return imageCompressed
        }
        else {
            
            compressedImageData = nil
            return nil
        }
    }
    
    // MARK:- Send Notification Token to Server
    public static func sendNotificationKey(pushNotificationService:PushNotificationService){
        if UserDefaults.standard.object(forKey: "NOTIFICATIONTOKEN") != nil {
            _ = Platform.getInstance().getUserManager().updateDeviceToken(token: UserDefaults.standard.object(forKey: "NOTIFICATIONTOKEN") as! String, notificationService: pushNotificationService)
        }
    }
    
}
