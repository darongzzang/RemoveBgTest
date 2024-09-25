//
//  ContentView.swift
//  RemoveBgTest
//
//  Created by 김이예은 on 9/25/24.
//

import SwiftUI
import Vision
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var image: UIImage?
    @State private var showingImagePicker: Bool = false
    
    var body: some View {
        VStack {
            Button(action: {
                showingImagePicker = true
            }, label: {
                Text("이미지 선택")
            })
            Image(uiImage: image ?? UIImage.cat)
                .resizable()
                .scaledToFit()
            Button("누끼 따기") {
                createSticker()
            }
        }.sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $image)
        }
        .padding()
    }
    
    // MARK: - Private
    
    private func createSticker() {
        var isLoading = true
        guard let inputImage = CIImage(image: image ?? UIImage.cat) else {
            print("Failed to create CIImage")
            return
        }
        processingQueue.async {
            guard let maskImage = subjectMaskImage(from: inputImage) else {
                print("Failed to create mask image")
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }
            let outputImage = apply(mask: maskImage, to: inputImage)
            let image = render(ciImage: outputImage)
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
    
    private func subjectMaskImage(from inputImage: CIImage) -> CIImage? {
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
    
    private func apply(mask: CIImage, to image: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = image
        filter.maskImage = mask
        filter.backgroundImage = CIImage.empty()
        return filter.outputImage!
    }
    
    private func render(ciImage: CIImage) -> UIImage {
        guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else {
            fatalError("Failed to render CGImage")
        }
        return UIImage(cgImage: cgImage)
    }
    private var processingQueue = DispatchQueue(label: "ProcessingQueue")
}

