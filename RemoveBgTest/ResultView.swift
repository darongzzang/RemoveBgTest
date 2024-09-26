//
//  ResultView.swift
//  RemoveBgTest
//
//  Created by 김이예은 on 9/26/24.
//

import SwiftUI
import Vision
import CoreImage.CIFilterBuiltins

struct ResultView: View {
    @Binding var newMaskImage: UIImage?
    @Binding var originalImage: UIImage?
    @State private var outputImage: UIImage?
    var body: some View {
        VStack {
            Image(uiImage: newMaskImage ?? .cat).resizable().frame(width: 400)
            Button(action: {
                createSticker()
            }, label: {
                Text("누끼 다시 따기")
            })
            Image(uiImage: outputImage ?? .cat).resizable().frame(width:400)
            
        }
    }
    
    func createSticker() {
        var isLoading = true
        
        // newMaskImage를 CIImage로 변환
        guard let maskImage = newMaskImage, let maskCIImage = CIImage(image: maskImage) else {
            print("Failed to create CIImage from newMaskImage")
            return
        }
        
        // originalImage를 CIImage로 변환
        guard let inputImage = originalImage else {
            print("originalImage is nil")
            return
        }
        
        guard let inputCIImage = CIImage(image: inputImage) else {
            print("Failed to create CIImage from originalImage. Check if the image is valid.")
            return
        }
        
        processingQueue.async {
            let outputImage = apply(mask: maskCIImage, to: inputCIImage)
            let image = render(ciImage: outputImage)
            DispatchQueue.main.async {
                self.outputImage = image // 결과 이미지 상태 변수 업데이트
            }
        }
        if let inputImage = originalImage {
            print("originalImage size: \(inputImage.size), scale: \(inputImage.scale)")
        }
    }
    
    func subjectMaskImage(from inputImage: CIImage) -> CIImage? {
        let handler = VNImageRequestHandler(ciImage: inputImage)
        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
        } catch {
            print(error)
            return nil
        }
        
        guard let result = request.results?.first else {
            print("No observations found")
            return nil
        }
        do {
            let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            return CIImage(cvPixelBuffer: maskPixelBuffer)
        } catch {
            print(error)
            return nil
        }
    }
    
    func apply(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }
    
    func render(ciImage: CIImage) -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Failed to render CGImage")
        }
        return UIImage(cgImage: cgImage)
    }
    
    var processingQueue = DispatchQueue(label: "ProcessingQueue")
}
