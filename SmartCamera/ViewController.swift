//
//  ViewController.swift
//  SmartCamera
//
//  Created by joon-ho kil on 2019/11/07.
//  Copyright © 2019 joon-ho kil. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var identifier: UILabel!
    @IBOutlet weak var confidence: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
     
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        guard let model = try? VNCoreMLModel(for: newEmojiAndCat().model) else {
            return
        }
        
        let request = VNCoreMLRequest(model: model){
            (finshedReq, err) in
            
            guard let results = finshedReq.results as? [VNRecognizedObjectObservation] else { return }
            guard let firstObservation = results.first else {
                DispatchQueue.main.async {
                    self.identifier.text = "인식된 물체 없음"
                    self.confidence.text = "0"
                }
                return
            }
            DispatchQueue.main.async {
                self.identifier.text = firstObservation.labels.first?.identifier
                self.confidence.text = String(firstObservation.labels.first!.confidence)
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}

