//
//  ContentViewModel.swift
//  Handlandmarker-MacOS
//
//  Created by Đoàn Văn Khoan on 3/2/25.
//

import SwiftUI
import AVFoundation
import Combine
import Cocoa

enum MoveDirection {
    case left, right
}

class ContentViewModel: ObservableObject {
    @Published var isGranted: Bool = false
    @Published var handLandmarks: [CGPoint] = []  /// Store as screen coordinates
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer?
    private var cancellables = Set<AnyCancellable>()
    
    /// Add a Timer to handle updates in sync with FPS
    private var updateTimer: Timer?
    private var lastUpdateTime = Date()
    
    /// Hand landmark left right
    private var previousPositions: [Int: CGPoint] = [:]
    @Published var actionStarted = false
    private var startTime: Date? = nil
    private var timeout: TimeInterval = 2.0 // 2 seconds timeout
    private var previousMiddlePositions: [CGFloat] = []
    @Published var direction: MoveDirection? = nil
    
    /// Hand landmark cursor
    @Published var isCursorActive = false
    private var trackingTimer: Timer?
    private var lastCursorPosition: CGPoint?
    private let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
    
    private var smoothFactor: CGFloat = 0.1  // Controls smoothing intensity

    
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

    // MARK: - FETCH HAND LANDMARKS
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
                            
                            /// Start process hand landmark
//                            let currentTime = Date()
//                            if currentTime.timeIntervalSince(self.lastUpdateTime) >= 0.033 {
//                                /// Update cursor only when more than 33ms has passed (1 frame)
//                                self.processMoveLeftRight(self.handLandmarks)
//                                self.processHandGesture(self.handLandmarks)
//                                self.lastUpdateTime = currentTime
//                            }
                            DispatchQueue.main.async {
                                self.processMoveLeftRight(self.handLandmarks)
                                self.processHandGesture(self.handLandmarks)
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

    // MARK: - CONVERT COORDINATES
    func convertToScreenCoordinates(x: Double, y: Double) -> CGPoint {
        let originalWidth: CGFloat = 1920
        let originalHeight: CGFloat = 1080

        let targetWidth: CGFloat = 600
        let targetHeight: CGFloat = 400

        /// Convert normalized coordinates (0.0 - 1.0) to original resolution (1920x1080)
        let realX = (1 - x) * originalWidth
        let realY = (y) * originalHeight

        /// Scale to the new resolution (600x400)
        let screenX = (realX / originalWidth) * targetWidth
        let screenY = (realY / originalHeight) * targetHeight


        return CGPoint(x: screenX, y: screenY)
    }
        
    // MARK: - GESTURE
    private func processHandGesture(_ points: [CGPoint]) {
        guard points.count >= 21 else { return }

        let thumbTip = points[4]
        let indexTip = points[8]

        let isTouching = distance(thumbTip, indexTip) < 20

        if isTouching && !isCursorActive {
            isCursorActive = true
            lastCursorPosition = indexTip
            print("Cursor control activated")
        } else if !isTouching && isCursorActive {
            isCursorActive = false
            print("Cursor control deactivated")
        }

        if isCursorActive, let lastPosition = lastCursorPosition {
            let deltaX = indexTip.x - lastPosition.x
            let deltaY = indexTip.y - lastPosition.y
            
            // Điều chỉnh tốc độ di chuyển con trỏ (scaleFactor)
            let scaleFactor: CGFloat = 2.0  // Tăng giá trị này để tăng tốc độ di chuyển của con trỏ
            moveCursor(deltaX: deltaX * scaleFactor, deltaY: deltaY * scaleFactor)
            lastCursorPosition = indexTip
        }
    }

    private func moveCursor(deltaX: CGFloat, deltaY: CGFloat) {
        let currentPosition = NSEvent.mouseLocation
        var newPosition = CGPoint(x: currentPosition.x + deltaX, y: currentPosition.y - deltaY)

        // Giới hạn di chuyển con trỏ không ra ngoài màn hình
        let screenFrame = NSScreen.main?.frame ?? CGRect.zero
        newPosition.x = min(max(newPosition.x, screenFrame.origin.x), screenFrame.origin.x + screenFrame.width)
        newPosition.y = min(max(newPosition.y, screenFrame.origin.y), screenFrame.origin.y + screenFrame.height)
        
        // Cập nhật vị trí con trỏ
        let move = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: newPosition,
            mouseButton: .left
        )
        move?.post(tap: .cghidEventTap)
    }
    
    // MARK: - MOVE LEFT RIGHT
    private func processMoveLeftRight(_ points: [CGPoint]) {
        guard points.count >= 21 else { return }
        self.handLandmarks = points
        
        let thumbTip = points[4]
        let indexTip = points[20]
        let middlePoints = [points[8], points[12], points[16]]
        
        /// Detect if action should start when thumb touches index
        if !actionStarted, distance(thumbTip, indexTip) < 20 {
            actionStarted = true
            print("Start")
            startTime = Date() // Start the timer when thumb and index touch
            previousMiddlePositions = middlePoints.map { $0.x }
            previousPositions = middlePoints.enumerated().reduce(into: [:]) { $0[$1.offset] = $1.element }
        }
        
        /// Check if action started and if we're within the 2-second window
        if actionStarted, let startTime = startTime, Date().timeIntervalSince(startTime) < timeout {
            /// Calculate the average horizontal movement of the middle fingers
            let currentMiddlePositions = middlePoints.map { $0.x }
            let avgCurrentPosition = currentMiddlePositions.reduce(0, +) / CGFloat(middlePoints.count)
            let avgPreviousPosition = previousMiddlePositions.reduce(0, +) / CGFloat(previousMiddlePositions.count)
            
            /// Detect movement direction based on average positions
            let movedLeft = avgCurrentPosition < avgPreviousPosition - 10
            let movedRight = avgCurrentPosition > avgPreviousPosition + 10
            
            /// Handle the swipe actions if movement is detected within the time window
            if movedLeft && !movedRight {
                print("Swipe Left detected")
                actionStarted = false
                direction = .left
            } else if movedRight && !movedLeft {
                print("Swipe Right detected")
                direction = .right
                actionStarted = false
            }
        } else if actionStarted {
            /// Reset if no movement detected within the 2-second window
            print("No movement detected within 2 seconds, resetting.")
            actionStarted = false
            startTime = nil
            previousPositions.removeAll()
            previousMiddlePositions.removeAll()
        }
    }
    
    // MARK: - DISTANT
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
    }
}
