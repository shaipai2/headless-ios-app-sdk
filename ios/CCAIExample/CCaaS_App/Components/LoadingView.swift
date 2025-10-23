//
//  LoadingView.swift
//  CCAIExample
//
//  Created by Shailesh Pai on 9/4/25.
//

import SwiftUI

struct LoadingView: View {
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State var dotCount: Int = 0
    var body: some View {
        VStack{
            Text("Please wait to be connected" + String(repeating: " . ", count: dotCount))
                .font(.headline)
                .foregroundColor(.blue)
                .onReceive(timer) { _ in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    dotCount = (dotCount + 1) % 4 // Cycle through 0, 1, 2, 3 dots
                                }
                            }
                .frame(width: 300, height: 50,alignment: .leading)
        }
        
    }
}

#Preview {
    LoadingView()
}
