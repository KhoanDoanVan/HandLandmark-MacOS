//
//  ContentView.swift
//  Handlandmarker-MacOS
//
//  Created by Đoàn Văn Khoan on 4/2/25.
//

import SwiftUI
import Network
import Cocoa


struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        ZStack {
            if viewModel.isGranted {
                PlayerContainerView(captureSession: viewModel.captureSession)
                    .frame(width: 600, height: 400)
                
                // Displaying hand landmarks
                Canvas { context, size in
                    for point in viewModel.handLandmarks {
                        let rect = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
                        context.fill(Path(ellipseIn: rect), with: .color(.green))
                    }
                }
                .frame(width: 600, height: 400)
                
                HStack {
                    Spacer()
                    VStack {
                        if let direction = viewModel.direction
                        {
                            switch direction {
                            case .left:
                                Text("⬅️")
                                    .font(.title)
                            case .right:
                                Text("➡️")
                                    .font(.title)
                            }
                        }
                        Spacer()
                    }
                }
            } else {
                Text("Camera access is denied or restricted.")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            viewModel.checkAuthorization()
        }
        .frame(width: 600, height: 400)
    }
}
