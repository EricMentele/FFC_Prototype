//
//  RecordViewController.swift
//  Filmer Prototype
//
//  Created by Eric Mentele on 9/3/15.
//  Copyright (c) 2015 Eric Mentele. All rights reserved.
//

import UIKit
import MediaPlayer
import MobileCoreServices
import AssetsLibrary

class RecordViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet var recordingView: UIView!
    @IBOutlet weak var capturedVideo: UIImageView!
    @IBOutlet weak var recordButton: UIButton!
    
    let movieCapture = AVCaptureSession()
    let movieTaker = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    let videoOutput = AVCaptureVideoDataOutput()
    var preview: AVCaptureVideoPreviewLayer!
    let timer = NSTimer()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        movieCapture.sessionPreset = AVCaptureSessionPresetMedium
        
        // add device as input to session.
        do {
            
            let input = try AVCaptureDeviceInput(device: movieTaker)
            movieCapture.addInput(input)
            
        } catch let captureError as NSError {
            
            print(captureError.localizedDescription)
            
        }
        
        movieCapture.addOutput(videoOutput)
        
        // set up a preview layer for displaying what the camera output.
        preview = AVCaptureVideoPreviewLayer(session: movieCapture)
        recordingView.layer.addSublayer(preview)
    }
    
    override func viewWillLayoutSubviews() {
        preview.frame = self.view.bounds
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        if preview.connection.supportsVideoOrientation {
            
            preview.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
            
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        
                movieCapture.startRunning()
    }

    @IBAction func recordClip(sender: AnyObject) {
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        // set timer for 3 seconds.
        // start timer on record.
        // record until timer hits 3 seconds.
        // when recording is finished, save to previous view and segue to it.
        
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
