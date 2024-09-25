//
//  ColorPickerView.swift
//  BrushTest2
//
//  Created by 김이예은 on 9/25/24.
//

import SwiftUI

struct ColorPickerView: View {
    let colors = [Color.black, Color.white]
    @Binding var selectedColor: Color
    
    var body: some View{
        HStack {
            ForEach(colors, id: \.self) { color in
                Image(systemName: selectedColor == color ? Constants.Icons.recordCircleFill : Constants.Icons.circleFill)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                    .clipShape(Circle())
                    .onTapGesture {
                        selectedColor = color
                    }
                
            }
        }
    }
}
