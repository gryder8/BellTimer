//
//  ScheduleDisplayTableViewController.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/21/19.
//  Copyright © 2019 Gavin Ryder. All rights reserved.
//


//TODO: Docs
//Use CMD + Option + /
import UIKit

extension UIView {
    func colorOfPoint(point: CGPoint) -> UIColor {
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        var pixelData: [UInt8] = [0, 0, 0, 0]

        let context = CGContext(data: &pixelData, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)

        context!.translateBy(x: -point.x, y: -point.y)

        self.layer.render(in: context!)

        let red: CGFloat = CGFloat(pixelData[0]) / CGFloat(255.0)
        let green: CGFloat = CGFloat(pixelData[1]) / CGFloat(255.0)
        let blue: CGFloat = CGFloat(pixelData[2]) / CGFloat(255.0)
        let alpha: CGFloat = CGFloat(pixelData[3]) / CGFloat(255.0)

        let color: UIColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)

        return color
    }
}

extension UIFont {
    func withTraits(traits:UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
    }

    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }
    
    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }

}

class ScheduleDisplayTableViewController: UITableViewController {
    
    private let MASTER: ScheduleMaster = ScheduleMaster.shared   //MARK: Properties
    private let tableGradient:GradientView = GradientView()
    var schedules:Array<String> = []
    private var darkModeEnabled:Bool = false
    private let CustomPeriodNames:ScheduleNames = ScheduleNames.shared
    
    //MARK: Properties
    //@IBOutlet weak var endTableText: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.darkModeEnabled = (self.traitCollection.userInterfaceStyle == .dark)
        if (darkModeEnabled){
            tableGradient.firstColor =   #colorLiteral(red: 0.01680417731, green: 0.2174809187, blue: 1, alpha: 1)
            tableGradient.secondColor =  #colorLiteral(red: 0.1045082286, green: 0.4720277933, blue: 0.9899627566, alpha: 1)
        } else {
            tableGradient.firstColor = #colorLiteral(red: 0.1045082286, green: 0.4720277933, blue: 0.9899627566, alpha: 1)
            tableGradient.secondColor = #colorLiteral(red: 0.01680417731, green: 0.2174809187, blue: 1, alpha: 1)
        }
        
        self.tableView.backgroundView = tableGradient
        
        // Uncomment the following line to preserve selection between presentations
        //self.clearsSelectionOnViewWillAppear = false
    }
    
//    private func customizePeriodName(stringWithDefaultPeriodName: String) -> String {
//        switch stringWithDefaultPeriodName {
//            //cases
//        case "Period 0": return PeriodNames.getPeriodNames()[0]
//        case "Period 1": return PeriodNames.getPeriodNames()[1]
//        case "Period 2": return PeriodNames.getPeriodNames()[2]
//        case "Period 3": return PeriodNames.getPeriodNames()[3]
//        case "Period 4": return PeriodNames.getPeriodNames()[4]
//        case "Period 5": return PeriodNames.getPeriodNames()[5]
//        case "Period 6": return PeriodNames.getPeriodNames()[6]
//        case "Period 7": return PeriodNames.getPeriodNames()[7]
//            //default
//        default: return stringWithDefaultPeriodName //don't modify
//
//        }
//    }
     
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default) //UIImage.init(named: "transparent.png")
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        self.navigationController?.navigationBar.tintColor = .black
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 //table never has more than 1 section
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        schedules = MASTER.getWholeScheduleForDay() //get the current schedule as an array
        return schedules.count //length of the array = num of cells
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { //loops through each cell
        //code here applies to each cell in the table view
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 40)
        tableView.separatorColor = UIColor(red:0.18, green:0.18, blue:0.18, alpha:0.5)
        schedules = MASTER.getWholeScheduleForDay()
        let cellIdentifier = "ScheduleTableViewCell" //CRUCIAL
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ScheduleTableViewCell else {
            fatalError("Dequeued cell not an instance of ScheduleTableViewCell")
        }
        cell.scheduleLabel.text = schedules[indexPath.row]
        cell.scheduleLabel.textColor = .black
        
        let cellText = cell.scheduleLabel.text!
        if (cellText.contains("Period")){
            let periodDesc:String = cellText.components(separatedBy: "-")[0] //just the period description
            let startIndex = periodDesc.index(periodDesc.endIndex, offsetBy: -1*("Period N ".count)) //count backwards from the end of the string
            let endIndex = periodDesc.index(periodDesc.endIndex, offsetBy: -2) //remove trailing space
            let periodSubstring = String(periodDesc[startIndex...endIndex])
            cell.scheduleLabel.text!.replaceSubrange(startIndex...endIndex, with: CustomPeriodNames.customizePeriodName(stringWithDefaultPeriodName: periodSubstring))
        }
        
        if (shouldCellBeHighlighted(scheduleCellContents: schedules[indexPath.row])) { //check if the current schedule description is the same as the one in the cell
            cell.backgroundColor = UIColor(red:0.47, green:0.96, blue:0.47, alpha:1.0) //light green
            cell.cellHighlighted = true;
        } else {
            cell.backgroundColor = .clear
            cell.cellHighlighted = false;
        }
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { //set up the title for the table header
        if (MASTER.canContinue()){
            return "Today's Schedule " + "("+MASTER.getScheduleType(myDate: Date())+")"
        }
        return ""
    }
    

    private func shouldCellBeHighlighted(scheduleCellContents: String) -> Bool { //determine whether a given cell should be highlighted given its data
        let scheduleNameOnly = scheduleCellContents.components(separatedBy: "-").first
        let currentPeriodDesc: String = MASTER.getCurrentBellTimeDescription();
        return scheduleNameOnly!.trimmingCharacters(in: CharacterSet.whitespaces) == currentPeriodDesc.trimmingCharacters(in: CharacterSet.whitespaces) //compare the two with whitespaces removed
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerFont: UIFont = UIFont (name: "Avenir Next", size: 17.0)!
        self.darkModeEnabled = (self.traitCollection.userInterfaceStyle == .dark)
        if (!darkModeEnabled) {
            (view as! UITableViewHeaderFooterView).contentView.backgroundColor = #colorLiteral(red: 0.09454231709, green: 0.4339366555, blue: 0.9914162755, alpha: 1)
        } else {
            (view as! UITableViewHeaderFooterView).contentView.backgroundColor = #colorLiteral(red: 0.02451096103, green: 0.2552438676, blue: 0.9992635846, alpha: 1)
        }
        (view as! UITableViewHeaderFooterView).textLabel?.font = headerFont.bold()
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = .black
    }
    
    
 
    
    // Override to support conditional editing of the table view.
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        // Return false if you do not want the specified item to be editable.
//        return true
//    }
    

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
