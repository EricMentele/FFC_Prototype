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
import AVFoundation
import Photos

class RecordViewController: UIViewController, UINavigationControllerDelegate,AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet var recordingView: UIView!
    @IBOutlet weak var capturedVideo: UIImageView!
    @IBOutlet weak var recordButton: UIButton!
    
    // Session components.
    var sessionQueue: dispatch_queue_t!
    let movieCapture = AVCaptureSession()
    let movieTaker = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    let videoPreviewOutput = AVCaptureVideoDataOutput()
    let videoCaptureOutput = AVCaptureMovieFileOutput()
    var maxVideoTime = CMTime(seconds: 3, preferredTimescale: 1)
    var preview: AVCaptureVideoPreviewLayer!
    
    // Photo library components
    var newClip: PHObjectPlaceholder!
    
    
    var backgroundRecordingID: UIBackgroundTaskIdentifier!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        movieCapture.sessionPreset = AVCaptureSessionPreset1280x720
        
        sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
        
        // add device as input to session.
        do {
            
            let input = try AVCaptureDeviceInput(device: movieTaker)
            movieCapture.addInput(input)
            
        } catch let captureError as NSError {
            
            print(captureError.localizedDescription)
            
        }
        
        movieCapture.addOutput(videoPreviewOutput)
        movieCapture.addOutput(videoCaptureOutput)
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
        
        videoCaptureOutput.maxRecordedDuration = maxVideoTime
        navigationController?.setNavigationBarHidden(true, animated: true)
        recordButton.alpha = 0
        recordButton.enabled = false
        
        // record for 3 seconds and save in background to photos
        dispatch_async(self.sessionQueue) { () -> Void in
        
            if !self.videoCaptureOutput.recording {
                // ensure that video will save even if user switches tasks.
                if UIDevice.currentDevice().multitaskingSupported {
                    
                    self.backgroundRecordingID = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
                }
                // set orientation to match preview layer.
                let videoCaptureOutputConnection = self.videoCaptureOutput.connectionWithMediaType(AVMediaTypeVideo)
                videoCaptureOutputConnection.videoOrientation = self.preview.connection.videoOrientation
                // record to a temporary file.
                let videoOutputFileName = NSProcessInfo().globallyUniqueString
                let videoOutputFilePath = NSTemporaryDirectory()
                let url = NSURL(fileURLWithPath: videoOutputFilePath).URLByAppendingPathComponent("mergeVideo-\(videoOutputFileName).mov")
                self.videoCaptureOutput.startRecordingToOutputFileURL(url, recordingDelegate: self)
                // save file to photos album.
                
            } else {
                
                self.videoCaptureOutput.stopRecording()
            }
        }
    }
    
    
    // MARK: Output recording delegate methods
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        
        print("Recording")
    }
    
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        // prepare cleanup function to reset recording file for next recording
        let currentBackgroundRecordingID = self.backgroundRecordingID
        self.backgroundRecordingID = UIBackgroundTaskInvalid
        
        let cleanup: dispatch_block_t = { () -> Void in
            
            do {
                
                try NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
            } catch let fileError as NSError {
                
                print(fileError.localizedDescription)
            }
            
            if currentBackgroundRecordingID != UIBackgroundTaskInvalid {
                
                UIApplication.sharedApplication().endBackgroundTask(currentBackgroundRecordingID)
            }
        }
        
        // handle success or failure of previous recording
        var success = true
        
        if (error != nil) {
            
            print("Did Finish Recording:",error.localizedDescription)
            success = error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as! Bool
        }
        
        // save file to Photos.
        if success {
            
            // check if authorized to save to photos
            PHPhotoLibrary.requestAuthorization({ (status:PHAuthorizationStatus) -> Void in
                
                if status == PHAuthorizationStatus.Authorized {
                    
                    // move movie to Photos library
                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                        
                        if #available(iOS 9.0, *) {
                        
                            let options = PHAssetResourceCreationOptions()
                            options.shouldMoveFile = true
                            let photosChangeRequest = PHAssetCreationRequest.creationRequestForAsset()
                            photosChangeRequest.addResourceWithType(PHAssetResourceType.Video, fileURL: outputFileURL, options: options)
                            self.newClip = photosChangeRequest.placeholderForCreatedAsset
                            

                        } else {
                            
                            // Fallback on earlier versions
                            PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(outputFileURL)
                        }
                        
                    }, completionHandler: { (success: Bool, error: NSError?) -> Void in
                            
                        if !success {
                            
                            print("Failed to save to photos: %@", error?.localizedDescription)
                        }
                        
                        cleanup()
                    })
                    
                    // save movie to correct album
                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                        
                        // add to Free Film Camp album
                        let fetchOptions = PHFetchOptions()
                        fetchOptions.predicate = NSPredicate(format: "title = %@", "Free Film Camp")
                        let album: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
                        let albumCollection = album.firstObject as! PHAssetCollection
                        let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: albumCollection, assets: album)
                        albumChangeRequest?.addAssets([self.newClip])
                        
                    }, completionHandler: { (success: Bool, error: NSError?) -> Void in
                            
                        if !success {
                            
                            print("Failed to add photo to album: %@", error?.localizedDescription)
                        }
                        
                        cleanup()
                    })
                    
                } else {
                    
                    cleanup()
                }
            })
        } else {
            
            cleanup()
        }
        
        // re-enable camera button for new recording
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            self.recordButton.enabled = true
            self.recordButton.alpha = 1
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
        
        print("End recording")
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
