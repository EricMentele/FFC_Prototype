//  Assisted by http://www.raywenderlich.com/94404/play-record-merge-videos-ios-swift
//  MergeViewController.swift
//  Filmer Prototype
//
//  Created by Eric Mentele on 9/3/15.
//  Copyright (c) 2015 Eric Mentele. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import CoreMedia
import AssetsLibrary
import MediaPlayer
import Photos

class MergeViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    let clipPicker = UIImagePickerController()
    
    var isSelectingAsset: Int!
    // video clip 1
    var firstAsset: AVAsset!
    // video clip 2
    var secondAsset: AVAsset!
    // video clip 3
    var thirdAsset: AVAsset!
    // sound track
    var audioAsset: AVAsset!
    // activity view indicator
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // movie selection
        clipPicker.delegate   = self
        clipPicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        clipPicker.mediaTypes = [kUTTypeMovie as String]
        // audio selection
    }

    @IBAction func loadAsset1(sender: AnyObject) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            
            isSelectingAsset = 1
            self.presentViewController(clipPicker, animated: true, completion: nil)
        }

    }
    
    @IBAction func loadAsset2(sender: AnyObject) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            
            isSelectingAsset = 2
            self.presentViewController(clipPicker, animated: true, completion: nil)
        }
    }
   
    @IBAction func loadAsset3(sender: AnyObject) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            
            isSelectingAsset = 3
            self.presentViewController(clipPicker, animated: true, completion: nil)
        }

        
    }
    @IBAction func loadAudio(sender: AnyObject) {
    }
    
    @IBAction func audioUnwindSegue(unwindSegue: UIStoryboardSegue){
        
    }
    
    @IBAction func mergeMedia(sender: AnyObject) {
        
        if firstAsset != nil && secondAsset != nil && thirdAsset != nil {
            
            // set up container to hold media tracks.
            let mixComposition = AVMutableComposition()
            // track times
            let track1to2Time = CMTimeAdd(firstAsset.duration, secondAsset.duration)
            let totalTime = CMTimeAdd(track1to2Time, thirdAsset.duration)
            // create separate video tracks for individual adjustments before merge
            let firstTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                
                try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration),
                    ofTrack: firstAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: kCMTimeZero)
            } catch let firstTrackError as NSError {
                
                print(firstTrackError.localizedDescription)
            }
            
            let secondTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                
                try secondTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAsset.duration),
                    ofTrack: secondAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: firstAsset.duration)
            } catch let secondTrackError as NSError {
                
                print(secondTrackError.localizedDescription)
            }
            
            let thirdTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                
                try thirdTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, thirdAsset.duration),
                    ofTrack: thirdAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: track1to2Time)
                
            } catch let thirdTrackError as NSError {
                
                print(thirdTrackError.localizedDescription)
            }

            // Set up an overall instructions array
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalTime)
            
            // Create seperate instructions for each track with helper method to correct orientation.
            let firstInstruction = videoCompositionInstructionForTrack(firstTrack, asset: firstAsset)
            // Make sure each track becomes transparent at end for the next one to play.
            firstInstruction.setOpacity(0.0, atTime: firstAsset.duration)
            let secondInstruction = videoCompositionInstructionForTrack(secondTrack, asset: secondAsset)
            secondInstruction.setOpacity(0.0, atTime: track1to2Time)
            let thirdInstruction = videoCompositionInstructionForTrack(thirdTrack, asset: thirdAsset)
            // Add individual instructions to main for execution.
            mainInstruction.layerInstructions = [firstInstruction, secondInstruction, thirdInstruction]
            let mainComposition = AVMutableVideoComposition()
            // Add instruction composition to main composition and set frame rate to 30 per second.
            mainComposition.instructions = [mainInstruction]
            mainComposition.frameDuration = CMTimeMake(1, 30)
            mainComposition.renderSize = mixComposition.naturalSize
            // get audio
            if audioAsset != nil {
                
                let audioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: 0)
                
                do {
                    
                    try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, totalTime), ofTrack: audioAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                        atTime: kCMTimeZero)
                    
                } catch let audioTrackError as NSError{
                        
                        print(audioTrackError.localizedDescription)
                }
            }
            // get path
            let paths: NSArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            
            let documentDirectory: String = paths[0] as! String
            let id = String(arc4random() % 1000)
            let url = NSURL(fileURLWithPath: documentDirectory).URLByAppendingPathComponent("mergeVideo-\(id).mov")
            // make exporter
            let exporter = AVAssetExportSession(
                asset: mixComposition,
                presetName: AVAssetExportPresetHighestQuality)
            exporter!.outputURL = url
            exporter!.outputFileType = AVFileTypeQuickTimeMovie
            exporter!.shouldOptimizeForNetworkUse = true
            exporter!.videoComposition = mainComposition
            exporter!
                .exportAsynchronouslyWithCompletionHandler() {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.exportDidFinish(exporter!)
                })
            }
        }
    }
    
    // MARK: Image Picker Methods
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // Get the media type
        let imageType: String = info[UIImagePickerControllerMediaType] as! String
        let url: NSURL = info[UIImagePickerControllerMediaURL] as! NSURL
        print(imageType)
        // Place movie in queue.
        if isSelectingAsset == 1 {
            
            print("Success loading 1")
            firstAsset = AVAsset(URL: url)
            
        } else if isSelectingAsset == 2 {
            print("Success loading 2")
            secondAsset = AVAsset(URL: url)
            
        } else if isSelectingAsset == 3 {
            print("Success loading 3")
            thirdAsset = AVAsset(URL: url)
        }
        
        // Dismiss movie selection.
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Merge Helper Methods
    func exportDidFinish(session:AVAssetExportSession) {
        
        assert(session.status == AVAssetExportSessionStatus.Completed, "Session status not completed")
        
        if session.status == AVAssetExportSessionStatus.Completed {
            
            let outputURL: NSURL = session.outputURL!
            let library = ALAssetsLibrary()
            if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(outputURL) {
                library.writeVideoAtPathToSavedPhotosAlbum(outputURL, completionBlock: { (assetURL: NSURL!, error: NSError!) -> Void in
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                        if (error != nil) {
                            
                            let alert = UIAlertView(title: "Error", message: "Failed to save video.", delegate: nil, cancelButtonTitle: "OK")
                            alert.show()
                        } else {
                            
                            let alert = UIAlertView(title: "Success", message: "Video saved.", delegate: nil, cancelButtonTitle: "OK")
                            alert.show()
                        }
                    })
                })
            }
        }
        audioAsset = nil
        firstAsset = nil
        secondAsset = nil
        thirdAsset = nil
    }

    // Identify the correct orientation for the output video based on the input.
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        
        var assetOrientation = UIImageOrientation.Up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .Right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .Left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .Up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .Down
        }
        return (assetOrientation, isPortrait)
    }
    
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        
        // get the asset tracks current orientation
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
//        let assetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0] 
//        let transform = assetTrack.preferredTransform
//        // identify the needed orientation
//        let assetInfo = orientationFromTransform(transform)
//        // find the size needed to fit the track in the screen for landscape
//        var scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.width
//        
//        // if it is portrait, get the size to fit the track in the screen and return instruction to scale.
//        if assetInfo.isPortrait {
//            
//            scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.height
//            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
//            instruction.setTransform(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor),
//                atTime: kCMTimeZero)
//            
//        } else {
//        
//            // If it is landscape then check for incorrect orientation and correct if needed, then return instructon to re-orient and scale.
//            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
//            var concat = CGAffineTransformConcat(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor), CGAffineTransformMakeTranslation(0, UIScreen.mainScreen().bounds.width / 2))
//            if assetInfo.orientation == .Down {
//                let fixUpsideDown = CGAffineTransformMakeRotation(CGFloat(M_PI))
//                let windowBounds = UIScreen.mainScreen().bounds
//                let yFix = assetTrack.naturalSize.height + windowBounds.height
//                let centerFix = CGAffineTransformMakeTranslation(assetTrack.naturalSize.width, yFix)
//                concat = CGAffineTransformConcat(CGAffineTransformConcat(fixUpsideDown, centerFix), scaleFactor)
//            }
//            instruction.setTransform(concat, atTime: kCMTimeZero)
//        }
        
        return instruction
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
