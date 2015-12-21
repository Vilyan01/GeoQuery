//
//  SearchViewController.swift
//  GeoQuery
//
//  Created by Brian Heller on 12/13/15.
//  Copyright © 2015 Brian Heller. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class SearchViewController: UIViewController {
    
    // Constants
    let deltaLat = 2.0
    let deltaLong = 2.0
    let deltaHeading = 7.5
    
    // user position and heading
    var location:CLLocation?
    var heading:CLLocationDirection?
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    // array to send to the table view
    var mountainArray:NSMutableArray?

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        // iterate through those mountains and if the direction is +/- 15 degrees from user heading add them to the array
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        mountainArray = NSMutableArray()
        // grab objects from within reasonable area of user
        let upperLat = (location?.coordinate.latitude)! + deltaLat
        let lowerLat = (location?.coordinate.latitude)! - deltaLat
        let upperLong = (location?.coordinate.longitude)! + deltaLong
        let lowerLong = (location?.coordinate.longitude)! - deltaLong
        print("Upper Lat: \(upperLat), Lower Lat: \(lowerLat), Upper Long \(upperLong), Lower Long: \(lowerLong)")
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchMountains = NSFetchRequest(entityName: "Mountain")
        let predicate = NSPredicate(format: "latitude >= %f AND latitude <= %f AND longitude >= %f AND longitude <= %f", lowerLat, upperLat, lowerLong, upperLong)
        fetchMountains.predicate = predicate
        do {
            let mountains = try managedContext.executeFetchRequest(fetchMountains)
            print("\(mountains.count) mountains in area")
            for mountain in mountains {
                let mountainLat = mountain.valueForKey("latitude") as! Float
                let mountainLong = mountain.valueForKey("longitude") as! Float
                let mtnCoord = CLLocation(latitude: Double(mountainLat), longitude: Double(mountainLong))
                let direction = findDirection(location!, mountainLocation: mtnCoord)
                let delta = abs(direction - self.heading!)
                if delta <= deltaHeading {
                    let mountainName = mountain.valueForKey("name") as! String
                    let elevation = mountain.valueForKey("elevation") as! Int
                    let mtn = Mountain()
                    mtn.name = mountainName
                    mtn.elevation = elevation
                    mtn.latitude = mountainLat
                    mtn.longitude = mountainLong
                    mtn.distance = Int(((location?.distanceFromLocation(mtnCoord))! / 1609.34))
                    mtn.direction = Int(direction)
                    
                    // calculate probability.  Less degrees delta the better
                    mtn.probability = (1.0 - delta / deltaHeading)
                    mountainArray?.addObject(mtn)
                }
            }
            // done adding mountains, go to next view
            activityIndicator.stopAnimating()
            // sort array by property
            mountainArray?.sortUsingComparator({ (obj1, obj2) -> NSComparisonResult in
                let obj1Mtn = obj1 as! Mountain
                let obj2Mtn = obj2 as! Mountain
                if obj1Mtn.probability > obj2Mtn.probability {
                    return NSComparisonResult.OrderedAscending
                }
                else if obj1Mtn.probability < obj2Mtn.probability {
                    return NSComparisonResult.OrderedDescending
                }
                else {
                    return NSComparisonResult.OrderedSame
                }
            })
            activityIndicator.stopAnimating()
            self.performSegueWithIdentifier("DisplayResults", sender: self)
        }
        catch let error as NSError {
            print("Error fetching mountains: \(error.localizedDescription)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController as! ResultsViewController
        destination.mountains = mountainArray
        destination.heading = Int(self.heading!)
    }
    

}

// MARK: - Private Functions

extension SearchViewController {
    private func findDirection(userLocation:CLLocation, mountainLocation:CLLocation) -> Double {
        let lat1 = degreesToRadians(userLocation.coordinate.latitude)
        let lon1 = degreesToRadians(userLocation.coordinate.longitude)
        
        let lat2 = degreesToRadians(mountainLocation.coordinate.latitude);
        let lon2 = degreesToRadians(mountainLocation.coordinate.longitude);
        
        let dLon = lon2 - lon1;
        
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x);
        if radiansBearing >= 0 {
            return radiansToDegrees(radiansBearing)
        }
        else {
            return 360 + radiansToDegrees(radiansBearing)
        }
    }
    private func degreesToRadians(degrees: Double) -> Double { return degrees * M_PI / 180.0 }
    private func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / M_PI }
}
