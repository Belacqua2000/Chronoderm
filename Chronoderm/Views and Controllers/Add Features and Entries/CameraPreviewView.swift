//
//  CameraPreviewView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 14/07/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import UIKit
import AVFoundation

class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
    /// Convenience wrapper to get layer as its statically known type.
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }

}
