//
//  ViewSelectViewController.swift
//  Filmer Prototype
//
//  Created by Eric Mentele on 9/3/15.
//  Copyright (c) 2015 Eric Mentele. All rights reserved.
//

import UIKit
import MobileCoreServices
import MediaPlayer
import Photos

class ViewSelectViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var playButton: UIButton!
    
    let moviePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: Check if sourcetype is available on current device.
        moviePicker.delegate = self
        moviePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        moviePicker.mediaTypes = [kUTTypeMovie as String]
        moviePicker.allowsEditing = true
        
    }
    
    @IBAction func playVideo(sender: AnyObject) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            self.presentViewController(moviePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // Get the media type
        let imageType: String = info[UIImagePickerControllerMediaType] as! String
        print(imageType)
        // Place movie in queue.
        // Dismiss movie selection.
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
