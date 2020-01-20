//
//  PeriodEditorTableViewController.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/19/20.
//  Copyright © 2020 Gavin Ryder. All rights reserved.
//

import UIKit

class PeriodEditorTableViewController: UITableViewController {
    
    private let MASTER: ScheduleMaster = ScheduleMaster.shared
    private let tableGradient:GradientView = GradientView()
    private let PeriodNames:ScheduleNames = ScheduleNames()
    var list:Array<String> = []
    private var darkModeEnabled:Bool = false
    var endY:CGFloat = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.darkModeEnabled = (self.traitCollection.userInterfaceStyle == .dark)
        if (darkModeEnabled){
            tableGradient.firstColor = UIColor(red:0.00, green:0.00, blue:1.00, alpha:0.8)
            tableGradient.secondColor = UIColor(red:0.00, green:0.30, blue:1.00, alpha:1.0)
        } else {
            tableGradient.firstColor = UIColor(red:0.00, green:0.60, blue:1.00, alpha:0.9)
            tableGradient.secondColor = UIColor(red:0.11, green:0.22, blue:1.00, alpha:0.86)
        }
       self.tableView.backgroundView = tableGradient
        
        // Uncomment the following line to preserve selection between presentations
        //self.clearsSelectionOnViewWillAppear = false
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1 //table never has more than 1 section
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        list = PeriodNames.getPeriodNames()
        return list.count
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        //self.list = PeriodNames.getPeriodNames()
        let editAction = UITableViewRowAction(style: .default, title: "Edit", handler: { (action, indexPath) in
            let alert = UIAlertController(title: "", message: "Edit list item", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in
                textField.text = self.list[indexPath.row]
            })
            alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (updateAction) in
                self.list[indexPath.row] = alert.textFields!.first!.text!
                self.PeriodNames.updateIndex(indexToModify: indexPath.row, newData: alert.textFields!.first!.text!)
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: false)
        })

        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
            self.list.remove(at: indexPath.row)
            tableView.reloadData()
        })

        return [deleteAction, editAction]
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { //set up the title for the table header
        if (MASTER.canContinue()){
            return "Current Period Names"
        }
        return ""
    }

    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {  //set up the title for the table footer
        if (MASTER.canContinue()){
            return "(Swipe left again to go back)"
        }
        return ""
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 40)
        tableView.separatorColor = UIColor(red:0.18, green:0.18, blue:0.18, alpha:0.5)
        self.list = PeriodNames.getPeriodNames()
        let cellIdentifier = "PeriodNameTableViewCell" //CRUCIAL
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PeriodNameTableViewCell else {
            fatalError("Dequeued cell not an instance of PeriodNameTableViewCell")
        }
        cell.periodNameLabel.text = list[indexPath.row]

        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerFont: UIFont = UIFont (name: "Avenir Next", size: 17.0)!
        (view as! UITableViewHeaderFooterView).contentView.backgroundColor = tableGradient.firstColor
        (view as! UITableViewHeaderFooterView).textLabel?.font = headerFont.bold()
        if (darkModeEnabled){
            (view as! UITableViewHeaderFooterView).textLabel?.textColor = .lightGray
        } else {
            (view as! UITableViewHeaderFooterView).textLabel?.textColor = UIColor(red:0.18, green:0.18, blue:0.18, alpha:1.0)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let headerFont: UIFont = UIFont (name: "Avenir Next", size: 17.0)!
        let xPos:CGFloat = self.tableGradient.bounds.midX //middle of the general UIView
        let yPos:CGFloat = endY
        (view as! UITableViewHeaderFooterView).contentView.backgroundColor = tableGradient.colorOfPoint(point: CGPoint(x: xPos,y: yPos))
        (view as! UITableViewHeaderFooterView).textLabel?.font = headerFont.italic() //make the footer font italic
        if (darkModeEnabled){
            (view as! UITableViewHeaderFooterView).textLabel?.textColor = .lightGray
        } else {
            (view as! UITableViewHeaderFooterView).textLabel?.textColor = .black
        }
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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


