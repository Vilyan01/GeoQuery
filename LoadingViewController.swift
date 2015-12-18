//
//  LoadingViewController.swift
//  GeoQuery
//
//  Created by Brian Heller on 12/13/15.
//  Copyright © 2015 Brian Heller. All rights reserved.
//

import UIKit
import CoreData

class LoadingViewController: UIViewController {
    // Outlets
    @IBOutlet weak var progressView: UIProgressView!
    
    // Session stuff
    let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
    var session:NSURLSession!
    
    // managed context
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var managedContext:NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        session = NSURLSession(configuration: sessionConfig)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        discoverCurrentVersion { (version) -> Void in
            self.managedContext = self.appDelegate.managedObjectContext
            
            let fetchVersion = NSFetchRequest(entityName: "Version")
            do {
                let versions = try self.managedContext.executeFetchRequest(fetchVersion)
                if versions.count > 0 {
                    let lastVersion = versions.last?.valueForKey("version") as! String
                    if lastVersion != version {
                        print("Getting new list!")
                        // DB is not up to date, clear DB and add new mountains to it
                    }
                    else {
                        // DB is up to date, just move to next view
                        print("Everything is up to date!")
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.progressView.setProgress(1.0, animated: true)
                            self.performSegueWithIdentifier("GoMain", sender: self)
                        })
                    }
                }
                else {
                    print("No versions found!")
                    // No versions, get the mountains and add to db
                    let firstVersion = NSEntityDescription.insertNewObjectForEntityForName("Version", inManagedObjectContext: self.managedContext)
                    firstVersion.setValue(version, forKey: "version")
                    // get mountains
                    self.getNewestMountainList({ () -> Void in
                        do {
                            try self.managedContext.save()
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.performSegueWithIdentifier("GoMain", sender: self)
                            })
                        }
                        catch let err as NSError {
                            print("Error Saving: \(err.localizedDescription)")
                        }
                    })
                }
            } catch let err as NSError {
                print("Error fetching Versions: \(err.localizedDescription)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

// #MARK - API Communnication

extension LoadingViewController {
    func discoverCurrentVersion(onComplete: (version:String) -> Void){
        let versionURL = NSURL(string: DB_VERSION)
        let request = NSURLRequest(URL: versionURL!)
        let versionTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            let httpResponse = response as! NSHTTPURLResponse
            if error != nil {
                print("Error: \(error?.localizedDescription)")
                return
            }
            if httpResponse.statusCode == 200 {
                do {
                    let responseDict = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves)
                    let currentVersion = responseDict.valueForKey("version") as! String
                    onComplete(version: currentVersion)
                    
                } catch let exception as NSError {
                    print("Caught exception: \(exception.localizedDescription)")
                }
            }
            else {
                print("Status Code: \(httpResponse.statusCode)")
            }
        }
        versionTask.resume()
    }
    
    func getNewestMountainList(onComplete: () -> Void) {
        let mountainURL = NSURL(string: GET_MOUNTAINS)
        let request = NSURLRequest(URL: mountainURL!)
        let mountainTask = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                print("Error: \(error!.localizedDescription)")
                return
            }
            
            let httpResponse = response as! NSHTTPURLResponse
            if httpResponse.statusCode == 200 {
                // all is good, store it in database
                do {
                    let mountainsDict = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableLeaves)
                    let mountains = mountainsDict.valueForKey("mountains") as! NSArray
                    var curProgress = 0
                    for mountain in mountains {
                        let name = mountain.valueForKey("name") as! String
                        let elevation = mountain.valueForKey("elevation") as! Int
                        let latitude = mountain.valueForKey("latitude") as! Float
                        let longitude = mountain.valueForKey("longitude") as! Float
                        let newMountain = NSEntityDescription.insertNewObjectForEntityForName("Mountain", inManagedObjectContext: self.managedContext)
                        newMountain.setValue(name, forKey: "name")
                        newMountain.setValue(elevation, forKey: "elevation")
                        newMountain.setValue(latitude, forKey: "latitude")
                        newMountain.setValue(longitude, forKey: "longitude")
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            curProgress++
                            self.progressView.setProgress((Float(curProgress) / Float(mountains.count)), animated: true)
                        })
                    }
                    onComplete()
                }
                catch let err as NSError {
                    print("Error: \(err.localizedDescription)")
                }
            }
            else {
                print("Status Code: \(httpResponse.statusCode)")
            }
        }
        mountainTask.resume()
    }
}
