//
//  SpeechEngine.swift
//  testspeech
//
//  Created by Nick Brook on 17/09/2016.
//  Copyright © 2016 NickBrook. All rights reserved.
//

import UIKit
import Speech
import AVFoundation


protocol SpeechEngineDelegate: class {
    func speechEngineDidStart(speechEngine: SpeechEngine)
    func speechEngine(_ speechEngine: SpeechEngine, didHypothesizeTranscription transcription: SFTranscription, withTranscriptionIdentifier identifier: UUID)
    func speechEngine(_ speechEngine: SpeechEngine, didFinishTranscription transcription: SFTranscription, withTranscriptionIdentifier identifier: UUID)
}

@available(iOS 10.0, *)
class SpeechEngine: NSObject {
    
    weak var delegate: SpeechEngineDelegate? = nil
    
    fileprivate var capture: AVCaptureSession?
    fileprivate var speechRequest: SFSpeechAudioBufferRecognitionRequest?
    fileprivate var recognizer: SFSpeechRecognizer?
    fileprivate var recognitionTask: SFSpeechRecognitionTask?
    fileprivate var transcriptionIdentifier: UUID?
    
    fileprivate var recognitionTimeoutTimer: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }
    
    var active: Bool = false {
        didSet {
            if active {
                self.startRecognizer()
            } else {
                self.endRecognizer()
            }
        }
    }
    
    var recognitionTimeout: TimeInterval = 1
    
    fileprivate func startTask() {
        self.recognitionTask?.finish()
        self.transcriptionIdentifier = UUID()
        self.speechRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionTask = self.recognizer?.recognitionTask(with: self.speechRequest!, delegate: self)
    }
    
    fileprivate func startRecognizer() {
        SFSpeechRecognizer.requestAuthorization { (status) in
            switch status {
            case .authorized:
                print("Authorized, starting recognizer")
                self.recognizer = SFSpeechRecognizer(locale: Locale.current)
                print("Initial available: \(self.recognizer?.isAvailable)")
                DispatchQueue.main.async {
                    self.startTask()
                    self.startCapture()
                    self.delegate?.speechEngineDidStart(speechEngine: self)
                }
            case .denied:
                fallthrough
            case .notDetermined:
                fallthrough
            case.restricted:
                print("User Autorization Issue.")
            }
        }
        
    }
    
    fileprivate func endRecognizer() {
        print("Ending recognizer")
        self.endCapture()
        self.speechRequest?.endAudio()
        self.recognitionTask?.cancel()
    }
    
    private func startCapture() {
        print("Starting capture")
        self.capture = AVCaptureSession()
        
        guard let audioDev = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio) else {
            print("Could not get capture device.")
            return
        }
        
        guard let audioIn = try? AVCaptureDeviceInput(device: audioDev) else {
            print("Could not create input device.")
            return
        }
        
        guard self.capture!.canAddInput(audioIn) else {
            print("Could not add input device")
            return
        }
        
        self.capture?.addInput(audioIn)
        
        let audioOut = AVCaptureAudioDataOutput()
        audioOut.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        guard self.capture!.canAddOutput(audioOut) else {
            print("Could not add audio output")
            return
        }
        
        self.capture!.addOutput(audioOut)
        audioOut.connection(withMediaType: AVMediaTypeAudio)
        self.capture!.startRunning()
        
        print("Capture running")
    }
    
    private func endCapture() {
        if true == self.capture?.isRunning {
            self.capture?.stopRunning()
        }
        print("Ended capture")
    }
}

extension SpeechEngine: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        self.speechRequest?.appendAudioSampleBuffer(sampleBuffer)
    }
    
}

extension SpeechEngine: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            print("Available")
        } else {
            print("Not available")
        }
    }
}

extension SpeechEngine: SFSpeechRecognitionTaskDelegate {
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        print("Detection began")
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        print("Hypothesised) \(transcription)")
        self.delegate?.speechEngine(self, didHypothesizeTranscription: transcription, withTranscriptionIdentifier: self.transcriptionIdentifier!)
        if self.recognitionTimeout > 0 {
            self.recognitionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: self.recognitionTimeout, repeats: false, block: { (timer) in
                task.finish()
            })
        }
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        print("Recognition result \(recognitionResult.bestTranscription)")
        
        if recognitionResult.isFinal {
            self.delegate?.speechEngine(self, didFinishTranscription: recognitionResult.bestTranscription, withTranscriptionIdentifier: self.transcriptionIdentifier!)
            self.startTask()
        }
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        print("Did finish successfully: \(successfully)")
        if !successfully && task.error != nil {
            print("Error: \(task.error!)")
        }
        self.startTask()
    }
    
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        print("cancelled")
    }
    
    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        print("Finished reading audio")
    }
}
