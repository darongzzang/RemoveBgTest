//
//  ResultView.swift
//  RemoveBgTest
//
//  Created by 김이예은 on 9/26/24.
//

import SwiftUI

struct ResultView: View {
    @Binding var image: UIImage?
    var body: some View {
        VStack {
            Image(uiImage: image ?? .cat).resizable().frame(width: 400)
        }
    }
}
