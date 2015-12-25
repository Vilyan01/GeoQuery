//
//  CameraViewController.swift
//  GeoQuery
//
//  Created by Brian Heller on 12/13/15.
//  Copyright © 2015 Brian Heller. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import MapKit
import CoreMotion

class CameraViewController: UIViewController {
    
    // Outlets
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var discoverButton: UIButton!
    
    // AVFoundation
    var session:AVCaptureSession?
    var inputDevice:AVCaptureDevice?
    var previewLayer:AVCaptureVideoPreviewLayer?
    var inputDeviceInput:AVCaptureDeviceInput?
    var stillImageOutput:AVCaptureStillImageOutput?
    
    // Location Manager
    var locationManager:CLLocationManager!
    var userLocation:CLLocation?
    var userHeading:CLLocationDirection?
    
    // Motion
    var motionLastYaw = 0.0
    var centerOfScreen:CGFloat?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Interface
        discoverButton.layer.cornerRadius = 5
        
        // AVFoundation
        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSessionPresetPhoto
        
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if device.hasMediaType(AVMediaTypeVideo) {
                if device.position == AVCaptureDevicePosition.Back {
                    inputDevice = device as? AVCaptureDevice
                }
            }
        }
        
        // Location Manager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingHeading()
        locationManager.requestWhenInUseAuthorization()
        
        // Notification Center
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dismissViewControllers", name: "Camera", object: nil)
        
        // Motion Kit
        let motionKit = MotionKit()
        motionKit.delegate = self
        motionKit.getAttitudeFromDeviceMotion(0.02, values: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        if AVCaptureDevice.devices().count > 0 {
            do {
                if let validInputDevice = inputDevice {
                    self.inputDeviceInput = try AVCaptureDeviceInput(device: validInputDevice)
                    session?.addInput(self.inputDeviceInput)
                }
            }
            catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            
            let viewLayer:CALayer = self.cameraView.layer
            
            previewLayer!.frame = viewLayer.bounds
            
            previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            cameraView.layer.addSublayer(previewLayer!)
            
            stillImageOutput = AVCaptureStillImageOutput()
            let captureSettings = NSDictionary(objects: [AVVideoCodecJPEG], forKeys: [AVVideoCodecKey])
            stillImageOutput?.outputSettings = captureSettings as! [NSObject : AnyObject]
            
            session?.addOutput(stillImageOutput)
            session!.startRunning()
            
            centerOfScreen = self.view.frame.width / CGFloat(2.0)
        }
        else {
            let alertController = UIAlertController(title: "Error", message: "It doesn't appear as if your device has a camera.  To use this applications functionality point your device in the direction of the mountain and tap discover", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction(title: "Ok", style: .Cancel, handler: { (action) -> Void in
                
            })
            alertController.addAction(okAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func dismissViewControllers() {
        print("Recieved notification")
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController as! SearchViewController
        if self.userLocation != nil {
            destination.location = self.userLocation
        }
        destination.heading = self.userHeading
        destination.rotation = self.motionLastYaw
    }


}

// #MARK - IBActions

extension CameraViewController {
    @IBAction func discoverButtonTapped(sender: AnyObject) {
        self.performSegueWithIdentifier("Search", sender: self)
    }
}

// #MARK - LocationManagerDelegate
extension CameraViewController : CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.userHeading = newHeading.trueHeading
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.userLocation = locations.last
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch(status) {
        case CLAuthorizationStatus.NotDetermined:
            print("Not Determined")
            locationManager.requestWhenInUseAuthorization()
            break
        case CLAuthorizationStatus.Denied:
            print("Denied")
            break
        default:
            self.discoverButton.enabled = true
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        }
    }
}

// #MARK - MotionKitDelegate
extension CameraViewController : MotionKitDelegate {
    func getAttitudeFromDeviceMotion(attitude: CMAttitude) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let quat = attitude.quaternion
            let yaw = asin(2*(quat.x * quat.z - quat.w * quat.y))
            
            if (self.motionLastYaw == 0) {
                self.motionLastYaw = yaw;
            }
            
            // kalman filtering
            let q = 0.1;   // process noise
            let r = 0.1;   // sensor noise
            var p = 0.1;   // estimated error
            var k = 0.5;   // kalman filter gain
            
            var x = self.motionLastYaw;
            p = p + q;
            k = p / (p + r);
            x = x + k*(yaw - x);
            p = (1 - k)*p;
            self.motionLastYaw = x;
        }
    }
}
