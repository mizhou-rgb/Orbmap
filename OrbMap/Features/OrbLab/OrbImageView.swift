import SwiftUI

struct OrbShaderParameters {
    var photoRange: Float = 1.60
    var primaryBlurRadius: Float = 72
    var surfaceBlurRadius: Float = 15.98
    var blueOffsetX: Float = -24
    var blueOffsetY: Float = 24
    var redOffsetX: Float = 24
    var redOffsetY: Float = -24
    var lowerLeftRippleFrequency: Float = 7.03
    var lowerLeftRippleAmount: Float = 0.16
    var lowerLeftRippleSpeed: Float = 1.70
    var rightDownRippleFrequency: Float = 6.96
    var rightDownRippleAmount: Float = 0.17
    var rightDownRippleSpeed: Float = 2.04
    var ripplePhase: Float = 2.82
    var pinchAmount: Float = 1.4
    var vignetteAmount: Float = 1.00
    var vignetteSize: Float = 0.76
    var vignetteFalloff: Float = 0.10
    var exposure: Float = 0.16
    var gamma: Float = 1.10
    var gamutMap: Float = 0.12
}

struct OrbImageView: View {
    let image: Image
    let imageAspectRatio: CGFloat
    let size: CGFloat
    let parameters: OrbShaderParameters

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
            orb(
                lowerLeftPhase: animatedPhase(
                    at: timeline.date,
                    speed: parameters.lowerLeftRippleSpeed,
                    offset: 3
                ),
                rightDownPhase: animatedPhase(
                    at: timeline.date,
                    speed: parameters.rightDownRippleSpeed,
                    offset: 0
                )
            )
        }
    }

    private func orb(
        lowerLeftPhase: Float,
        rightDownPhase: Float
    ) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .layerEffect(
                ShaderLibrary.orbRemap(
                    .boundingRect,
                    .float(imageAspectRatio),
                    .float(parameters.photoRange)
                ),
                maxSampleOffset: CGSize(width: size, height: size)
            )
            .layerEffect(
                ShaderLibrary.gaussianBlurHorizontal31(
                    .float(parameters.primaryBlurRadius),
                    .float(6.5)
                ),
                maxSampleOffset: blurOffset(parameters.primaryBlurRadius)
            )
            .layerEffect(
                ShaderLibrary.gaussianBlurVertical31(
                    .float(parameters.primaryBlurRadius),
                    .float(6.5)
                ),
                maxSampleOffset: blurOffset(parameters.primaryBlurRadius)
            )
            .layerEffect(
                ShaderLibrary.orbBlueShift(
                    .boundingRect,
                    .float2(
                        parameters.blueOffsetX,
                        parameters.blueOffsetY
                    )
                ),
                maxSampleOffset: rgbOffset
            )
            .layerEffect(
                ShaderLibrary.orbLowerLeftRipple(
                    .boundingRect,
                    .float(parameters.lowerLeftRippleAmount),
                    .float(parameters.lowerLeftRippleFrequency),
                    .float(lowerLeftPhase)
                ),
                maxSampleOffset: distortionOffset
            )
            .layerEffect(
                ShaderLibrary.orbPinch(
                    .boundingRect,
                    .float(parameters.pinchAmount)
                ),
                maxSampleOffset: CGSize(width: size, height: size)
            )
            .layerEffect(
                ShaderLibrary.orbRightDownRipple(
                    .boundingRect,
                    .float(parameters.rightDownRippleAmount),
                    .float(parameters.rightDownRippleFrequency),
                    .float(rightDownPhase)
                ),
                maxSampleOffset: distortionOffset
            )
            .layerEffect(
                ShaderLibrary.orbRedShift(
                    .boundingRect,
                    .float2(
                        parameters.redOffsetX,
                        parameters.redOffsetY
                    )
                ),
                maxSampleOffset: rgbOffset
            )
            .layerEffect(
                ShaderLibrary.gaussianBlurHorizontal31(
                    .float(parameters.surfaceBlurRadius),
                    .float(5.0)
                ),
                maxSampleOffset: blurOffset(parameters.surfaceBlurRadius)
            )
            .layerEffect(
                ShaderLibrary.gaussianBlurVertical31(
                    .float(parameters.surfaceBlurRadius),
                    .float(5.0)
                ),
                maxSampleOffset: blurOffset(parameters.surfaceBlurRadius)
            )
            .layerEffect(
                ShaderLibrary.orbVignette(
                    .boundingRect,
                    .float(parameters.vignetteAmount),
                    .float(parameters.vignetteSize),
                    .float(parameters.vignetteFalloff)
                ),
                maxSampleOffset: .zero
            )
            .colorEffect(
                ShaderLibrary.orbExposure(
                    .float(parameters.exposure),
                    .float(parameters.gamma),
                    .float(parameters.gamutMap)
                )
            )
    }

    private func animatedPhase(
        at date: Date,
        speed: Float,
        offset: Float
    ) -> Float {
        let phase = (date.timeIntervalSinceReferenceDate * Double(speed))
            .truncatingRemainder(dividingBy: 2 * .pi)
        return parameters.ripplePhase + offset + Float(phase)
    }

    private var distortionOffset: CGSize {
        CGSize(width: size * 0.08, height: size * 0.08)
    }

    private var rgbOffset: CGSize {
        let horizontal = max(
            abs(parameters.blueOffsetX),
            abs(parameters.redOffsetX)
        )
        let vertical = max(
            abs(parameters.blueOffsetY),
            abs(parameters.redOffsetY)
        )
        return CGSize(width: CGFloat(horizontal), height: CGFloat(vertical))
    }

    private func blurOffset(_ radius: Float) -> CGSize {
        CGSize(width: CGFloat(radius), height: CGFloat(radius))
    }
}
