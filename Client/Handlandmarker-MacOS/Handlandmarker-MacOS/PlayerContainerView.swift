//
//  PlayerContainerView.swift
//  Handlandmarker-MacOS
//
//  Created by Đoàn Văn Khoan on 3/2/25.
//

import SwiftUI
import Foundation
import AVFoundation
import Combine

class PlayerView: NSView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    init(captureSession: AVCaptureSession) {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        super.init(frame: .zero)
        setupLayer()
    }

    func setupLayer() {
        previewLayer?.frame = self.bounds
        previewLayer?.contentsGravity = .resizeAspectFill
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.connection?.automaticallyAdjustsVideoMirroring = false
        
        self.previewLayer?.connection?.isVideoMirrored = true
        
        layer = previewLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



struct PlayerContainerView: NSViewRepresentable {
    typealias NSViewType = PlayerView

    let captureSession: AVCaptureSession

    init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
    }

    func makeNSView(context: Context) -> PlayerView {
        return PlayerView(captureSession: captureSession)
    }

    func updateNSView(_ nsView: PlayerView, context: Context) { }
}
