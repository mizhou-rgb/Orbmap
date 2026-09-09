//
//  AudioLevelMonitor.swift
//  Memorize
//
//  Created by MI ZHOU on 6/2/26.
//

import Foundation
import AVFoundation
import Observation

@Observable
class AudioLevelMonitor {
    var level: CGFloat = 0.1

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func startMonitoring() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let url = URL(fileURLWithPath: "/dev/null")

            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatAppleLossless,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]

            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()

            timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
                self?.recorder?.updateMeters()

                let power = self?.recorder?.averagePower(forChannel: 0) ?? -60
                let normalized = max(0.05, min(1.0, (power + 60) / 60))

                DispatchQueue.main.async {
                    self?.level = CGFloat(normalized)
                }
            }
        } catch {
            print("Audio monitoring failed: \(error)")
        }
    }

    func stopMonitoring() {
        recorder?.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
    }
}

