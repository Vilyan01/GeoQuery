//
//  MountainInfoViewController.swift
//  GeoQuery
//
//  Created by Brian Heller on 12/13/15.
//  Copyright © 2015 Brian Heller. All rights reserved.
//

import UIKit

class MountainInfoViewController: UIViewController {
    
    @IBOutlet weak var userHeadingLabel: UILabel!
    @IBOutlet weak var mountainDirectionLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var elevationLabel: UILabel!
    @IBOutlet weak var name: UILabel!
    var mountain:Mountain?
    var userHeading:Int?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if mountain != nil {
            self.latitudeLabel.text = "\(mountain!.latitude)"
            self.longitudeLabel.text = "\(mountain!.longitude)"
            self.elevationLabel.text = "\(mountain!.elevation) Feet"
            self.name.text = mountain!.name
            self.userHeadingLabel.text = "\(self.userHeading!)°"
            self.mountainDirectionLabel.text = "\(mountain!.direction)"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBack(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
