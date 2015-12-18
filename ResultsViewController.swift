//
//  ResultsViewController.swift
//  GeoQuery
//
//  Created by Brian Heller on 12/13/15.
//  Copyright © 2015 Brian Heller. All rights reserved.
//

import UIKit

class ResultsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var mountains:NSArray?
    var selectedMountain:Mountain?

    override func viewDidLoad() {
        super.viewDidLoad()
        if mountains == nil {
            // Didn't get an array from the search view controller.  Init an empty one and display error
            mountains = NSArray()
            print("No array")
        }
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GetDetails" {
            let destination = segue.destinationViewController as! MountainInfoViewController
            destination.mountain = self.selectedMountain
        }
    }
}

// MARK: - TableViewDelegate
extension ResultsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mountains!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let mountain = mountains?.objectAtIndex(indexPath.row) as! Mountain
        let cell = tableView.dequeueReusableCellWithIdentifier("MountainCell")
        let mtnNameLabel = cell?.viewWithTag(100) as! UILabel
        let distanceLabel = cell?.viewWithTag(101) as! UILabel
        let probabilityLabel = cell?.viewWithTag(102) as! UILabel
        mtnNameLabel.text = mountain.name
        distanceLabel.text = "\(mountain.distance) Miles"
        probabilityLabel.text = "\(Int(mountain.probability * 100))%"
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedMountain = mountains?.objectAtIndex(indexPath.row) as? Mountain
        self.performSegueWithIdentifier("GetDetails", sender: self)
    }
}
