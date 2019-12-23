//
//  ScheduleDisplayTableViewController.swift
//  Bell View
//
//  Created by Gavin Ryder on 1/21/19.
//  Copyright © 2019 Gavin Ryder. All rights reserved.
//

import UIKit

class ScheduleDisplayTableViewController: UITableViewController {
    private let MASTER: ScheduleMaster = ScheduleMaster.shared   //MARK: Properties
    var schedules:Array<String> = []
    
    //MARK: Properties
    @IBOutlet weak var endTableText: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.tableView.tableHeaderView = "Today's Schedule"
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let headerView = UIView()
        let headerColor = headerView.backgroundColor
        endTableText.backgroundColor = headerColor
        schedules = MASTER.getWholeScheduleForDay()
        return schedules.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
 
        schedules = MASTER.getWholeScheduleForDay()
        let cellIdentifier = "ScheduleTableViewCell" //CRUCIAL
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? ScheduleTableViewCell else {
            fatalError("Dequeued cell not an instance of ScheduleTableViewCell")
        }
        //let sched = schedules[indexPath.row]
        cell.scheduleLabel.text = schedules[indexPath.row]
        
        //***TODO: highlights period 0 on scroll back up (bug)***

        if (shouldCellBeHighlighted(scheduleCellContents: schedules[indexPath.row])) {
            cell.backgroundColor = UIColor(red:0.56, green:0.79, blue:0.99, alpha:1.0)//light blue

        }
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (MASTER.canContinue()){
        return "Today's Schedule " + "("+MASTER.getScheduleType(myDate: Date())+")"
        }
        return ""
    }
    
    private func shouldCellBeHighlighted(scheduleCellContents: String) -> Bool {
        let scheduleNameOnly = scheduleCellContents.components(separatedBy: "-").first
        let currentPeriodDesc: String = MASTER.getCurrentBellTimeDescription();
        return scheduleNameOnly!.trimmingCharacters(in: CharacterSet.whitespaces) == currentPeriodDesc.trimmingCharacters(in: CharacterSet.whitespaces) //compare the two with whitespaces removed
            
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
