//
//  Handlandmarker_MacOSApp.swift
//  Handlandmarker-MacOS
//
//  Created by Đoàn Văn Khoan on 3/2/25.
//

//import SwiftUI
//import AVFoundation
//
@main
struct Handlandmarker_MacOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
//
//
//struct CameraView: NSViewRepresentable {
//    class CameraViewController: NSView {
//        var previewLayer: AVCaptureVideoPreviewLayer?
//
//        override init(frame frameRect: NSRect) {
//            super.init(frame: frameRect)
//            setupCamera()
//        }
//
//        required init?(coder: NSCoder) {
//            fatalError("init(coder:) has not been implemented")
//        }
//
//        func setupCamera() {
//            let session = AVCaptureSession()
//            session.sessionPreset = .high
//            guard let camera = AVCaptureDevice.default(for: .video),
//                  let input = try? AVCaptureDeviceInput(device: camera)
//            else { return }
//
//            if session.canAddInput(input) {
//                session.addInput(input)
//            }
//
//            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
//            previewLayer.videoGravity = .resizeAspectFill
//            previewLayer.frame = bounds
//            layer = previewLayer
//            self.previewLayer = previewLayer
//
//            session.startRunning()
//        }
//    }
//
//    func makeNSView(context: Context) -> CameraViewController {
//        return CameraViewController()
//    }
//
//    func updateNSView(_ nsView: CameraViewController, context: Context) {}
//}
//
//struct HandTrackerView: View {
//    @State private var handLandmarks: [[String: Double]] = []
//
//    var body: some View {
//        VStack {
//            CameraView() // Show macOS camera
//                .frame(width: 640, height: 480)
//
//            Text("Hand Tracking")
//                .font(.largeTitle)
//
//            ForEach(handLandmarks.indices, id: \.self) { index in
//                Text("Point \(index): x=\(handLandmarks[index]["x"]!), y=\(handLandmarks[index]["y"]!)")
//            }
//        }
//        .onAppear {
//            fetchHandLandmarks()
//        }
//    }
//
//    func fetchHandLandmarks() {
//        guard let url = URL(string: "http://localhost:5000/hand_landmarks") else { return }
//        
//        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
//            URLSession.shared.dataTask(with: url) { data, _, _ in
//                if let data = data {
//                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                       let landmarks = json["landmarks"] as? [[String: Double]] {
//                        DispatchQueue.main.async {
//                            self.handLandmarks = landmarks
//                        }
//                    }
//                }
//            }.resume()
//        }
//    }
//}

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        ZStack {
            if viewModel.isGranted {
                PlayerContainerView(captureSession: viewModel.captureSession)
                    .frame(width: 640, height: 480)
                                
                // Displaying hand landmarks
                if viewModel.handLandmarks.count == 0 {
                    Text("Nothing checking")
                } else {
                    ForEach(viewModel.handLandmarks.indices, id: \.self) { index in
                        Text("Point \(index): x=\(viewModel.handLandmarks[index]["x"] ?? 0), y=\(viewModel.handLandmarks[index]["y"] ?? 0)")
                            .padding(2)
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
    }
}


//struct ContentView: View {
//    var body: some View {
//        HandTrackerView()
//    }
//}
