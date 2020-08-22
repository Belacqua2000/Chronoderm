//
//  ImageExtension.swift
//  Chronoderm
//
//  Created by Nick Baughan on 16/08/2020.
//

import UIKit

public extension UIImage {
    func croppedImage(inRect rect: CGRect) -> UIImage {
        let rad: (Double) -> CGFloat = { deg in
            return CGFloat(deg / 180.0 * .pi)
        }
        var rectTransform: CGAffineTransform
        switch imageOrientation {
        case .left:
            let rotation = CGAffineTransform(rotationAngle: rad(90))
            rectTransform = rotation.translatedBy(x: 0, y: -size.height)
        case .right:
            let rotation = CGAffineTransform(rotationAngle: rad(-90))
            rectTransform = rotation.translatedBy(x: -size.width, y: 0)
        case .down:
            let rotation = CGAffineTransform(rotationAngle: rad(-180))
            rectTransform = rotation.translatedBy(x: -size.width, y: -size.height)
        default:
            rectTransform = .identity
        }
        rectTransform = rectTransform.scaledBy(x: scale, y: scale)
        let transformedRect = rect.applying(rectTransform)
        let imageRef = cgImage!.cropping(to: transformedRect)!
        let result = UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
        return result
    }
    
    func flipped() -> UIImage {
        guard let cgimage = cgImage else { return self }
        let newOrientation: UIImage.Orientation
        switch imageOrientation {
        case .up:
            newOrientation = .upMirrored
        case .down:
            newOrientation = .downMirrored //Tested
        case .left:
            newOrientation = .rightMirrored
        case .right:
            newOrientation = .leftMirrored //Tested
        case .upMirrored:
            newOrientation = .up
        case .downMirrored:
            newOrientation = .down
        case .leftMirrored:
            newOrientation = .right
        case .rightMirrored:
            newOrientation = .left
        @unknown default:
            newOrientation = .up
            print("Unknown orientation")
        }
        return UIImage(cgImage: cgimage, scale: scale, orientation: newOrientation)
    }
}
