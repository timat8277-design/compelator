//
//  ExteraCamera120FPS.swift
//  extera-ios
//
//  Created for exteraGram iOS.
//  Запись видеосообщений (кружков) в 120 FPS / 60 FPS без рассинхрона,
//  поддержка ультраширокоугольной камеры и ползунок зума в стиле Google Camera.
//

import UIKit
import AVFoundation

public class ExteraCamera120FPSController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    // MARK: - Настройки
    public var targetFPS: Int32 = 120
    public var startWithUltraWide: Bool {
        get { UserDefaults.standard.bool(forKey: "extera_cam_start_ultrawide") }
        set { UserDefaults.standard.set(newValue, forKey: "extera_cam_start_ultrawide") }
    }

    // MARK: - AVFoundation
    private let captureSession = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let audioOutput = AVCaptureAudioDataOutput()
    private let sessionQueue = DispatchQueue(label: "org.extera.cameraQueue")

    // UI
    private let previewLayer = AVCaptureVideoPreviewLayer()
    private let circularMaskLayer = CAShapeLayer()
    private let zoomSlider = UISlider()
    private let zoomLabel = UILabel()
    private let recordButton = UIButton(type: .custom)
    private let fpsBadge = UILabel()

    // Запись без рассинхронизации (AVAssetWriter)
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterAudioInput: AVAssetWriterInput?
    private var isRecording = false
    private var sessionStartTime: CMTime = .invalid
    private var outputFileURL: URL?

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupCaptureSession()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        setupCircularMask()
    }

    // MARK: - UI Setup

    private func setupUI() {
        previewLayer.session = captureSession
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // FPS Badge
        fpsBadge.translatesAutoresizingMaskIntoConstraints = false
        fpsBadge.text = "\(targetFPS) FPS PRO"
        fpsBadge.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        fpsBadge.textColor = .systemGreen
        fpsBadge.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        fpsBadge.layer.cornerRadius = 8
        fpsBadge.clipsToBounds = true
        fpsBadge.textAlignment = .center
        view.addSubview(fpsBadge)

        // Google Camera Zoom Slider
        zoomSlider.translatesAutoresizingMaskIntoConstraints = false
        zoomSlider.minimumValue = 1.0
        zoomSlider.maximumValue = 5.0
        zoomSlider.value = 1.0
        zoomSlider.tintColor = UIColor.systemTeal
        zoomSlider.addTarget(self, action: #selector(didChangeZoom(_:)), for: .valueChanged)
        view.addSubview(zoomSlider)

        zoomLabel.translatesAutoresizingMaskIntoConstraints = false
        zoomLabel.text = "1.0x"
        zoomLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        zoomLabel.textColor = .white
        view.addSubview(zoomLabel)

        // Кнопка записи кружка
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.backgroundColor = .systemRed
        recordButton.layer.cornerRadius = 36
        recordButton.layer.borderWidth = 4
        recordButton.layer.borderColor = UIColor.white.cgColor
        recordButton.addTarget(self, action: #selector(toggleRecord), for: .touchUpInside)
        view.addSubview(recordButton)

        NSLayoutConstraint.activate([
            fpsBadge.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            fpsBadge.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fpsBadge.widthAnchor.constraint(equalToConstant: 100),
            fpsBadge.heightAnchor.constraint(equalToConstant: 24),

            zoomSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            zoomSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            zoomSlider.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -30),

            zoomLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            zoomLabel.bottomAnchor.constraint(equalTo: zoomSlider.topAnchor, constant: -8),

            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            recordButton.widthAnchor.constraint(equalToConstant: 72),
            recordButton.heightAnchor.constraint(equalToConstant: 72)
        ])
    }

    private func setupCircularMask() {
        let size = min(view.bounds.width - 40, 360)
        let circleRect = CGRect(x: (view.bounds.width - size) / 2, y: (view.bounds.height - size) / 2 - 40, width: size, height: size)
        
        let path = UIBezierPath(ovalIn: circleRect)
        circularMaskLayer.path = path.cgPath
        circularMaskLayer.strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor
        circularMaskLayer.fillColor = UIColor.clear.cgColor
        circularMaskLayer.lineWidth = 3.0

        if circularMaskLayer.superlayer == nil {
            view.layer.addSublayer(circularMaskLayer)
        }
    }

    // MARK: - Capture Session & 120 FPS Configuration

    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .inputPriority

            // Выбор камеры: ультраширик или основная
            var chosenDevice: AVCaptureDevice?
            if self.startWithUltraWide, let ultraWide = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
                chosenDevice = ultraWide
            } else {
                chosenDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ??
                               AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            }

            guard let device = chosenDevice else { return }
            self.videoDevice = device

            // Настройка 120 FPS / 60 FPS
            self.configureHighFrameRate(device: device, desiredFPS: self.targetFPS)

            if let input = try? AVCaptureDeviceInput(device: device), self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
                self.videoInput = input
            }

            // Аудио вход для устранения рассинхронизации
            if let mic = AVCaptureDevice.default(for: .audio),
               let micInput = try? AVCaptureDeviceInput(device: mic),
               self.captureSession.canAddInput(micInput) {
                self.captureSession.addInput(micInput)
                self.audioInput = micInput
            }

            // Видео выход
            self.videoOutput.alwaysDiscardsLateVideoFrames = false
            self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }

            // Аудио выход
            self.audioOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
            if self.captureSession.canAddOutput(self.audioOutput) {
                self.captureSession.addOutput(self.audioOutput)
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
        }
    }

    private func configureHighFrameRate(device: AVCaptureDevice, desiredFPS: Int32) {
        do {
            try device.lockForConfiguration()

            var bestFormat: AVCaptureDevice.Format?
            var maxFPSAvailable: Double = 30.0

            for format in device.formats {
                for range in format.videoSupportedFrameRateRanges {
                    if range.maxFrameRate >= Double(desiredFPS) {
                        bestFormat = format
                        maxFPSAvailable = range.maxFrameRate
                        break
                    }
                }
            }

            if let format = bestFormat {
                device.activeFormat = format
                let fps = min(Double(desiredFPS), maxFPSAvailable)
                let frameDuration = CMTime(value: 1, timescale: Int32(fps))
                device.activeVideoMinFrameDuration = frameDuration
                device.activeVideoMaxFrameDuration = frameDuration

                DispatchQueue.main.async { [weak self] in
                    self?.fpsBadge.text = "\(Int(fps)) FPS PRO"
                }
            }
            device.unlockForConfiguration()
        } catch {
            print("[ExteraCamera] Ошибка настройки FPS: \(error)")
        }
    }

    // MARK: - Zoom Control (Google Camera style)

    @objc private func didChangeZoom(_ slider: UISlider) {
        guard let device = videoDevice else { return }
        do {
            try device.lockForConfiguration()
            let zoomFactor = CGFloat(slider.value)
            device.videoZoomFactor = max(1.0, min(zoomFactor, device.activeFormat.videoMaxZoomFactor))
            device.unlockForConfiguration()

            zoomLabel.text = String(format: "%.1fx", slider.value)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch {
            print("[ExteraCamera] Zoom error: \(error)")
        }
    }

    // MARK: - Запись без рассинхрона (AVAssetWriter)

    @objc private func toggleRecord() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let fileManager = FileManager.default
            let tempDir = fileManager.temporaryDirectory
            let outputURL = tempDir.appendingPathComponent("extera_circle_\(UUID().uuidString).mp4")
            try? fileManager.removeItem(at: outputURL)

            do {
                self.assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

                // Видео: квадратное разрешение 720x720 для кружка, битрейт под 120 FPS
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: 720,
                    AVVideoHeightKey: 720,
                    AVVideoCompressionPropertiesKey: [
                        AVVideoAverageBitRateKey: 6_000_000,
                        AVVideoExpectedSourceFrameRateKey: self.targetFPS,
                        AVVideoMaxKeyFrameIntervalKey: self.targetFPS
                    ]
                ]

                let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                videoInput.expectsMediaDataInRealTime = true
                self.assetWriter?.add(videoInput)
                self.assetWriterVideoInput = videoInput

                // Аудио: AAC 48kHz стерео
                let audioSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 48000,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderBitRateKey: 128000
                ]

                let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
                audioInput.expectsMediaDataInRealTime = true
                self.assetWriter?.add(audioInput)
                self.assetWriterAudioInput = audioInput

                self.outputFileURL = outputURL
                self.sessionStartTime = .invalid
                self.isRecording = true

                DispatchQueue.main.async {
                    self.recordButton.backgroundColor = .white
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }
            } catch {
                print("[ExteraCamera] Ошибка инициализации AssetWriter: \(error)")
            }
        }
    }

    private func stopRecording() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.isRecording else { return }
            self.isRecording = false

            self.assetWriterVideoInput?.markAsFinished()
            self.assetWriterAudioInput?.markAsFinished()

            self.assetWriter?.finishWriting {
                DispatchQueue.main.async {
                    self.recordButton.backgroundColor = .systemRed
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if let url = self.outputFileURL {
                        print("[ExteraCamera] Кружок успешно записан в 120 FPS: \(url.path)")
                    }
                }
            }
        }
    }

    // MARK: - AVCapture Delegates

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording, let writer = assetWriter else { return }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        if sessionStartTime == .invalid {
            sessionStartTime = timestamp
            writer.startWriting()
            writer.startSession(atSourceTime: timestamp)
        }

        if output == videoOutput, assetWriterVideoInput?.isReadyForMoreMediaData == true {
            assetWriterVideoInput?.append(sampleBuffer)
        } else if output == audioOutput, assetWriterAudioInput?.isReadyForMoreMediaData == true {
            assetWriterAudioInput?.append(sampleBuffer)
        }
    }
}
