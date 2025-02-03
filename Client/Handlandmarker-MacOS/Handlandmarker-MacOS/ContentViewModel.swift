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
    @Published var handLandmarks: [[String: Double]] = []
    
    var captureSession: AVCaptureSession!
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
        
        // Fetch hand landmarks when session is ready
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

    // Fetch hand landmarks from a local server (adjust URL as needed)
    func fetchHandLandmarks() {
        guard let url = URL(string: "http://192.168.1.147:1999/hand_landmarks") else {
            print("Invalid URL")
            return
        }

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            URLSession.shared.dataTask(with: url) { data, response, error in
                // Handle network error
                if let error = error {
                    print("Network error: \(error.localizedDescription)")
                    return
                }

                // Handle invalid response status
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Invalid server response")
                    return
                }

                // Handle missing data
                guard let data = data else {
                    print("No data received")
                    return
                }

                // Attempt to parse the JSON safely
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let landmarks = json["landmarks"] as? [[String: Double]] {
                        DispatchQueue.main.async {
                            self.handLandmarks = landmarks
                            print("Landmarks: \(landmarks)")
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
}
