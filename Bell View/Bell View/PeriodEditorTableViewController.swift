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
    private let PeriodNames:ScheduleNames = ScheduleNames.shared
    var list:Array<String> = []
    private var darkModeEnabled:Bool = false
    var endY:CGFloat = 0
    

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
        //self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setUpTableViewHeader()
    }
    
    private func setUpTableViewHeader(){
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default) //UIImage.init(named: "transparent.png")
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = .clear
        self.navigationController?.navigationBar.tintColor = .black
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done,target: self, action: #selector(backTapped))
        let label = UILabel(frame: CGRect(x:0, y:0, width:350, height:30))
        label.backgroundColor = .clear
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 14.0)
        label.textAlignment = .center
        label.textColor = .black
        label.text = "Swipe right on a period name to edit"
        self.navigationItem.titleView = label
    }
    
    @objc func backTapped(){
        navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
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
        let editAction = UITableViewRowAction(style: .normal, title: "Edit", handler: { (action, indexPath) in
            let alert = UIAlertController(title: "", message: "Edit period name", preferredStyle: .alert)
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

        return [editAction]
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { //set up the title for the table header
        if (MASTER.canContinue()){
            return "Current Period Names"
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
        cell.periodNameLabel.textAlignment = .center
        cell.backgroundColor = .clear
        cell.periodNameLabel.textColor = .black

        return cell
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
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    

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


