//
//  ContentViewModel.swift
//  Handlandmarker-MacOS
//
//  Created by Đoàn Văn Khoan on 3/2/25.
//

import SwiftUI
import AVFoundation
import Combine

class ContentViewModel: ObservableObject {
    @Published var isGranted: Bool = false
    @Published var handLandmarks: [CGPoint] = []  /// Store as screen coordinates
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        captureSession = AVCaptureSession()
        setupBindings()
        checkAuthorization()
    }

    func setupBindings() {
        $isGranted
            .sink { [weak self] isGranted in
                if isGranted {
                    self?.prepareCamera()
                } else {
                    self?.stopSession()
                }
            }
            .store(in: &cancellables)
        
        /// Fetch hand landmarks when session is ready
        $isGranted
            .sink { [weak self] isGranted in
                if isGranted {
                    self?.fetchHandLandmarks()
                }
            }
            .store(in: &cancellables)
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.isGranted = true
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.isGranted = granted
                    }
                }
            case .denied, .restricted:
                self.isGranted = false
            @unknown default:
                fatalError()
        }
    }
    
    func startSession() {
        guard !captureSession.isRunning else { return }
        captureSession.startRunning()
    }

    func stopSession() {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
    }

    func prepareCamera() {
        captureSession.sessionPreset = .high

        if let device = AVCaptureDevice.default(for: .video) {
            startSessionForDevice(device)
        }
    }

    func startSessionForDevice(_ device: AVCaptureDevice) {
        do {
            let input = try AVCaptureDeviceInput(device: device)
            addInput(input)
            startSession()
        } catch {
            print("Error starting session: \(error.localizedDescription)")
        }
    }

    func addInput(_ input: AVCaptureInput) {
        guard captureSession.canAddInput(input) else {
            return
        }
        captureSession.addInput(input)
    }

    func fetchHandLandmarks() {
        guard let url = URL(string: "http://127.0.0.1:1999/hand_landmarks") else {
            print("Invalid URL")
            return
        }

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Invalid server response")
                    return
                }

                guard let data = data else {
                    print("No data received")
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let landmarks = json["landmarks"] as? [[String: Double]] {
                        
                        DispatchQueue.main.async {
                            self.handLandmarks = landmarks.compactMap { landmark in
                                guard let x = landmark["x"], let y = landmark["y"] else { return nil }
                                return self.convertToScreenCoordinates(x: x, y: y)
                            }
                        }
                    } else {
                        print("Invalid JSON structure")
                    }
                } catch {
                    print("JSON parsing error: \(error.localizedDescription)")
                }
            }.resume()
        }
    }

    func convertToScreenCoordinates(x: Double, y: Double) -> CGPoint {
        let originalWidth: CGFloat = 1920
        let originalHeight: CGFloat = 1080

        let targetWidth: CGFloat = 600
        let targetHeight: CGFloat = 400

        /// Convert normalized coordinates (0.0 - 1.0) to original resolution (1920x1080)
        let realX = x * originalWidth
        let realY = y * originalHeight

        /// Scale to the new resolution (600x400)
        let screenX = (realX / originalWidth) * targetWidth
        let screenY = (realY / originalHeight) * targetHeight

        print("Converted (\(x), \(y)) -> (\(screenX), \(screenY))") /// Debug Output

        return CGPoint(x: screenX, y: screenY)
    }
}
