//
//  ContentView.swift
//  Handlandmarker-MacOS
//
//  Created by Đoàn Văn Khoan on 4/2/25.
//

import SwiftUI
import Network
import Cocoa

//struct ContentView: View {
//    @StateObject private var viewModel = ContentViewModel()
//
//    var body: some View {
//        ZStack {
//            if viewModel.isGranted {
//                PlayerContainerView(captureSession: viewModel.captureSession)
//                    .frame(width: 640, height: 480)
//                                
//                // Displaying hand landmarks
////                if viewModel.handLandmarks.count == 0 {
////                    Text("Nothing checking")
////                } else {
////                    ForEach(viewModel.handLandmarks.indices, id: \.self) { index in
////                        Text("Point \(index): x=\(viewModel.handLandmarks[index]["x"] ?? 0), y=\(viewModel.handLandmarks[index]["y"] ?? 0)")
////                            .padding(2)
////                    }
////                }
////                
//                Canvas { context, size in
//                    for point in viewModel.handLandmarks {
//                        print(point)
//                        let rect = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
//                        context.fill(Path(ellipseIn: rect), with: .color(.red))
//                    }
//                }
//            } else {
//                Text("Camera access is denied or restricted.")
//                    .foregroundColor(.red)
//            }
//        }
//        .onAppear {
//            viewModel.checkAuthorization()
//        }
//    }
//}

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
                        print(point)
                        let rect = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
                        context.fill(Path(ellipseIn: rect), with: .color(.green))
                    }
                }
                .frame(width: 600, height: 400)
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
