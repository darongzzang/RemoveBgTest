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
    @State private var maskImage: UIImage? = nil // maskImage 상태 변수 추가
    @State private var outputImage: UIImage? = nil // 결과 이미지를 저장할 상태 변수 추가
    
    var body: some View {
        VStack {
            Button(action: {
                showingImagePicker = true
            }, label: {
                Text("이미지 선택")
            })
            
            // 선택한 이미지 표시
            Image(uiImage: image ?? UIImage(named: "cat")!) // 기본 이미지 설정
                .resizable()
                .scaledToFit()
            
            // 결과 이미지 표시
            if let output = outputImage {
                Image(uiImage: output)
                    .resizable()
                    .scaledToFit()
                    .padding()
            }
            
            // maskImage 표시
            if let mask = maskImage { // maskImage가 있을 때만 표시
                Image(uiImage: mask)
                    .resizable()
                    .scaledToFit()
                    .colorInvert() // 검정-하양으로 보이도록 색상 반전
                    .padding()
            }
            
            Button("누끼 따기") {
                createSticker()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $image)
        }
        .padding()
    }
    
    // MARK: - Private
    
    private func createSticker() {
        var isLoading = true
        guard let inputImage = CIImage(image: image ?? UIImage(named: "cat")!) else {
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
            
            // maskImage 상태 변수 업데이트
            DispatchQueue.main.async {
                self.maskImage = render(ciImage: maskImage) // maskImage를 UIImage로 변환하여 저장
            }
            
            let outputImage = apply(mask: maskImage, to: inputImage)
            let image = render(ciImage: outputImage)
            DispatchQueue.main.async {
                self.outputImage = image // 결과 이미지 상태 변수 업데이트
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
