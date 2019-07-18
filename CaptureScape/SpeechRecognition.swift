//
//  SpeechRecognition.swift
//  CaptureScape
//
//  Created by David on 7/13/19.
//  Copyright © 2019 David Hartzog. All rights reserved.
//

import Foundation
import Speech

class SpeechRecognizer: SFSpeechRecognizer {
    
    let audioEngine = AVAudioEngine()
    //let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest() //used for live audio
    //let urlRequest = SFSpeechURLRecognitionRequest() //used for prerecorded audio
    var recognitionTask: SFSpeechRecognitionTask?
    
    
    func transcribePrerecordedAudio(url: NSURL) -> String? {
        print(url)
        
        var transcribedText: String?
        
        guard let speechRecognizer = SFSpeechRecognizer() else {
            print("speechRecognizer = nil")
            return nil
        }
        
        if !speechRecognizer.isAvailable {
            print("speechRecognizer = not available")
            return nil
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url as URL)
        speechRecognizer.recognitionTask(with: request) { (result, error) in
            guard let result = result else {
                print("resulting text is nil")
                return
            }
            
            if result.isFinal {
                //print("transcribed text is: ", result.bestTranscription.formattedString)
                transcribedText = result.bestTranscription.formattedString
                
                print("(TranscribedPrerecordedAudio) transcribed text: ", transcribedText)
            }
            else {
                print("result.isFinal is not final")
            }
        }
        
        return transcribedText
    }
    
}

