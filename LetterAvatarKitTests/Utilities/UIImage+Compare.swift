//
// UIImage+TestsUtilities.swift
// LetterAvatarKitTests
//
// Copyright 2017 Victor Peschenkov
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// o this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import UIKit

extension UIImage {
    /// Returns the named image from test bundle.
    ///
    /// - name: The name of the image. For images in asset
    /// catalogs, specify the name of the image asset. For PNG
    /// image files, specify the filename without the filename
    /// extension. For all other image file formats, include
    /// the filename extension in the name.
    convenience init?(named name: String) {
        self.init(
            named: name,
            in: Bundle(identifier: "org.peschenkov.LetterAvatarKit.LetterAvatarKitTests"),
            compatibleWith: nil
        )
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let image = object as? UIImage else {
            return false
        }
        return compareImages(with: image, tolerance: 0.01)
    }
    
    open func compareImages(with image: UIImage?, tolerance: CGFloat) -> Bool {
        guard let image = image else {
            return false
        }
        
        guard self.size == image.size else {
            return false
        }
        
        var lhsImage: CGImage? = self.cgImage
        var rhsImage: CGImage? = image.cgImage
        let convertToSuitableByteOrder = { (image: UIImage, size: CGSize) -> CGImage? in
            defer {
                UIGraphicsEndImageContext()
            }
            UIGraphicsBeginImageContext(size)
            if UIGraphicsGetCurrentContext() != nil {
                image.draw(in: CGRect(
                    x: 0,
                    y: 0,
                    width: size.width,
                    height: size.height
                ))
                return UIGraphicsGetImageFromCurrentImageContext()?.cgImage
            }
            return nil
        }
        
        if #available(iOS 12.0, *) {
            if lhsImage?.byteOrderInfo != rhsImage?.byteOrderInfo {
                lhsImage = convertToSuitableByteOrder(self, self.size)
                rhsImage = convertToSuitableByteOrder(image, image.size)
            }
        } else {
            lhsImage = convertToSuitableByteOrder(self, self.size)
            rhsImage = convertToSuitableByteOrder(image, image.size)
        }
        
        guard let lhs = lhsImage, let rhs = rhsImage else {
            return false
        }
        
        guard let lhsData = lhs.dataProvider?.data,
              let rhsData = rhs.dataProvider?.data else {
                return false
        }
        
        if lhsData == rhsData {
            return true
        } else {
            guard let lhsPixelsPointer: UnsafePointer<UInt8> = CFDataGetBytePtr(lhsData),
                  let rhsPixelsPointer: UnsafePointer<UInt8> = CFDataGetBytePtr(rhsData) else {
                    return false
            }
            var errorCount = 0
            let numberOfPixels = Int(self.size.width * self.size.height * 4)
            for i in stride(from: 0, to: numberOfPixels, by: 1) {
                if lhsPixelsPointer[i] != rhsPixelsPointer[i] {
                    errorCount += 1
                    let error = CGFloat(CGFloat(errorCount) / CGFloat(numberOfPixels))
                    if error > tolerance {
                        return false
                    }
                }
            }
            return true
        }
    }
}
