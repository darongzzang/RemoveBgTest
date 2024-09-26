//
//  BrushView.swift
//  RemoveBgTest
//
//  Created by 김이예은 on 9/26/24.
//

import SwiftUI

struct Line {
    var points = [CGPoint]()
    var color: Color = .black
    var lineWidth: Double = 5.0
}

struct BrushView: View {
    @State private var currentLine = Line()
    @State private var lines: [Line] = []
    @State private var selectedColor: Color = .black
    @State private var thickness: Double = 0.0
    @Binding var backgroundImage: UIImage?
    @Binding var originalImage: UIImage?
    @State var savedImage: UIImage?
    
    @State private var currentZoom = 0.0
    @State private var totalZoom = 1.0
    
    
    var body: some View{
        VStack {
            ZStack {
                Image(uiImage: backgroundImage ?? UIImage(named: "mask")!)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                ///사진 확대/축소 메서드 구현해보기
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                currentZoom = value.magnification - 1
                            }
                            .onEnded { value in
                                totalZoom += currentZoom
                                currentZoom = 0
                            }
                    )
                    .accessibilityZoomAction { action in
                        if action.direction == .zoomIn {
                            totalZoom += 1
                        } else {
                            totalZoom -= 1
                        }
                    }
                Canvas { context, size in
                    for line in lines {
                        var path = Path()
                        path.addLines(line.points)
                        context.stroke(path, with: .color(line.color), lineWidth: line.lineWidth)
                    }
                    
                }
                .background(Color.clear)
                .frame(minWidth: 400, minHeight: 400)
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged({ value in
                        let newPoint = value.location
                        currentLine.points.append(newPoint)
                        self.lines.append(currentLine)
                    })
                        .onEnded({ value in
                            self.currentLine = Line(points: [], color: selectedColor, lineWidth: thickness)
                        })
                )
            }.frame(width: 400, height: 400)
            
            Slider(value: $thickness, in: 1...20) {
                Text("Thickness")
            }.frame(maxWidth: 200)
                .onChange(of: thickness) { newThickness in
                    currentLine.lineWidth = newThickness
                }
            
            Divider()
            
            ColorPickerView(selectedColor: $selectedColor)
                .onChange(of: selectedColor) { newColor in
                    currentLine.color = newColor
                }
            NavigationLink(destination: ResultView(newMaskImage: $savedImage, originalImage: $originalImage)) {
                                Text("Go to Brush View")
                            }
            Button("Save Image") {
                let image = self.zStackAsImage()
                        saveImageToPhotos(image: image)
                        savedImage = image
                    }
        }
    }
    // ZStack의 내용을 이미지로 변환하는 메서드
        private func zStackAsImage() -> UIImage {
            let zStackView = ZStack {
                Image(uiImage: backgroundImage ?? UIImage(named: "mask")!)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                Canvas { context, size in
                    for line in lines {
                        var path = Path()
                        path.addLines(line.points)
                        context.stroke(path, with: .color(line.color), lineWidth: line.lineWidth)
                    }
                }
                .background(Color.clear)
                .frame(minWidth: 400, minHeight: 400)
            }
            
            return zStackView.asImage()
        }
}

extension View {
    /// ZStack 안의 요소들만 이미지로 추출하는 함수
    func asImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        // ZStack의 크기를 설정합니다.
        let targetSize = CGSize(width: 400, height: 400)
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        // UIGraphicsImageRenderer를 사용하여 이미지를 렌더링합니다.
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            // ZStack의 내용을 그립니다.
            view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
        }
    }
    
    
}


func saveImageToPhotos(image: UIImage) {
    ///사용자 갤러리에 사진을 저장하는 함수
//    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    return
}

