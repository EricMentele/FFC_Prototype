//
//  ViewController.swift
//  Filmer Prototype
//
//  Created by Eric Mentele on 9/3/15.
//  Copyright (c) 2015 Eric Mentele. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class ViewController: UIViewController {
    
    var isShowingLandscapeView = false
    
    let movieViewer = UIImagePickerController()
    
    // dedicated album creation
    let photoLibrary = PHPhotoLibrary.sharedPhotoLibrary()
    let fetchOptions = PHFetchOptions()
    let albumTitle = "Free Film Camp"
    var album: PHFetchResult!
    var found = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // detect device orientation
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged:", name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        // set up movie viewer
        movieViewer.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        movieViewer.mediaTypes = [kUTTypeMovie as String]
        
        
        // set up to check for and create dedicated photo album
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
        album = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        if let _: AnyObject = album.firstObject {
            
            self.found = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // creat dedicated photo album if needed
        if !found {
            photoLibrary.performChanges({ () -> Void in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle("Free Film Camp")
                }) { (success: Bool, error: NSError?) -> Void in
                    if !success {
                        print(error!.localizedDescription)
                    }
            }
        }
    }

    @IBAction func viewMovies(sender: AnyObject) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            
            self.presentViewController(movieViewer, animated: true, completion: nil)
        }
        isShowingLandscapeView = false
    }
    
    func orientationChanged(orientationChanged: NSNotification) {
        
        let deviceOrientation = UIDevice.currentDevice().orientation
        if UIDeviceOrientationIsLandscape(deviceOrientation) && !isShowingLandscapeView {
            
            self.performSegueWithIdentifier("recordVC", sender: self)
            isShowingLandscapeView = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

