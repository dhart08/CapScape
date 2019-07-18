//
//  AudioExtractor.swift
//  CaptureScape
//
//  Created by David on 7/15/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import Foundation
import AVFoundation

class AudioExtractor {
    
    static func extractAudioFromVideo(url: URL) -> String? {
        //let videoAsset: AVAsset = AVAsset(url: url)
        let videoAsset: AVURLAsset? = AVURLAsset(url: url)
        if videoAsset == nil {
            print("videoAsset is nil")
            return nil
        }
        
        //let composition = AVMutableCompositionTrack()
        let compositionVideoTrack = videoAsset?.tracks
        
        let exportSession = AVAssetExportSession(asset: videoAsset!, presetName: AVAssetExportPresetAppleM4A)
        
        let timeStart = CMTimeMakeWithSeconds(0.0, 1)
        let timeRange = CMTimeRangeMake(timeStart, videoAsset!.duration)
        exportSession?.timeRange = timeRange
        
        exportSession?.outputFileType = AVFileType.m4a
        
        var outputURL = url
        outputURL.deletePathExtension()
        outputURL.appendPathExtension("m4a")
        print("OutputURL: ", outputURL)
        exportSession?.outputURL = outputURL
        
        print("Audio export started...")
        exportSession?.exportAsynchronously(completionHandler: {
            print("Audio export done!")
        })
        return nil
    }
}
