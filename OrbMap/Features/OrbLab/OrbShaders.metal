#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// MARK: - Coordinate helpers

float2 orbPoint(float2 position, float4 bounds) {
    float2 center = bounds.xy + bounds.zw * 0.5;
    float radius = min(bounds.z, bounds.w) * 0.5;
    return (position - center) / radius;
}

float2 orbPosition(float2 point, float4 bounds) {
    float2 center = bounds.xy + bounds.zw * 0.5;
    float radius = min(bounds.z, bounds.w) * 0.5;
    return center + point * radius;
}

float2 orbSourceUV(float2 point, float photoRange) {
    float radius = length(point);
    float radiusSquared = min(radius * radius, 0.999);
    float sphereDepth = sqrt(1.0 - radiusSquared);

    // Keep the center readable while compressing the outer image like a lens.
    float refraction = mix(0.84, 0.50, 1.0 - sphereDepth);
    float2 lensPoint = point * refraction;

    // Continuous angular bending creates a wrapped shell without a 2-pi seam.
    float angle = atan2(point.y, point.x);
    float shell = smoothstep(0.30, 0.94, radius);
    float2 tangent = float2(-sin(angle), cos(angle));
    float2 radial = float2(cos(angle), sin(angle));
    float angularBend = sin(angle * 2.0 + 0.30) * 0.11 * shell * shell;
    float2 wrappedPoint = lensPoint
        + tangent * angularBend
        - radial * (0.10 * shell * shell);

    float shellMix = smoothstep(0.22, 0.76, radius);
    float2 sourcePoint = mix(point * 0.76, wrappedPoint, shellMix);
    sourcePoint *= max(photoRange, 0.1);
    return clamp(0.5 + sourcePoint * 0.5, float2(0.002), float2(0.998));
}

float2 fittedImageUV(float2 imageUV, float aspectRatio) {
    float safeAspectRatio = max(aspectRatio, 0.001);
    float2 fittedSize = safeAspectRatio >= 1.0
        ? float2(1.0, 1.0 / safeAspectRatio)
        : float2(safeAspectRatio, 1.0);
    float2 fittedOrigin = (1.0 - fittedSize) * 0.5;
    return fittedOrigin + imageUV * fittedSize;
}

// MARK: - Lightweight Gaussian

half4 gaussian17(
    float2 position,
    SwiftUI::Layer layer,
    float2 axis,
    float sigma
) {
    float safeSigma = max(sigma, 0.01);
    float inverseVariance = 0.5 / (safeSigma * safeSigma);
    float centerWeight = 1.0;
    half4 accumulatedColor = layer.sample(position) * half(centerWeight);
    float accumulatedWeight = centerWeight;

    // Pair adjacent Gaussian taps into one linearly filtered sample. This
    // keeps a soft 17-tap kernel while reducing it to 9 texture reads.
    for (int index = 1; index <= 7; index += 2) {
        float firstOffset = float(index);
        float secondOffset = float(index + 1);
        float firstWeight = exp(
            -(firstOffset * firstOffset) * inverseVariance
        );
        float secondWeight = exp(
            -(secondOffset * secondOffset) * inverseVariance
        );
        float pairWeight = firstWeight + secondWeight;
        float pairedOffset = (
            firstOffset * firstWeight
            + secondOffset * secondWeight
        ) / pairWeight;

        accumulatedColor += (
            layer.sample(position + axis * pairedOffset)
            + layer.sample(position - axis * pairedOffset)
        ) * half(pairWeight);
        accumulatedWeight += pairWeight * 2.0;
    }

    float outerWeight = exp(-64.0 * inverseVariance);
    accumulatedColor += (
        layer.sample(position + axis * 8.0)
        + layer.sample(position - axis * 8.0)
    ) * half(outerWeight);
    accumulatedWeight += outerWeight * 2.0;

    return accumulatedColor / half(accumulatedWeight);
}

[[ stitchable ]]
half4 gaussianBlurHorizontal31(
    float2 position,
    SwiftUI::Layer layer,
    float radius,
    float sigma
) {
    float spacing = max(radius, 0.0) / 12.0;
    return gaussian17(position, layer, float2(spacing, 0.0), sigma);
}

[[ stitchable ]]
half4 gaussianBlurVertical31(
    float2 position,
    SwiftUI::Layer layer,
    float radius,
    float sigma
) {
    float spacing = max(radius, 0.0) / 12.0;
    return gaussian17(position, layer, float2(0.0, spacing), sigma);
}

// MARK: - Rectangular image to seam-free orb surface

[[ stitchable ]]
half4 orbRemap(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float aspectRatio,
    float photoRange
) {
    float2 imageUV = orbSourceUV(
        orbPoint(position, bounds),
        photoRange
    );
    float2 sourceUV = fittedImageUV(imageUV, aspectRatio);
    return layer.sample(bounds.xy + sourceUV * bounds.zw);
}

// MARK: - Independent RGB shifts

[[ stitchable ]]
half4 orbBlueShift(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float2 offset
) {
    float2 point = orbPoint(position, bounds);
    float r = length(point);

    half4 center = layer.sample(position);

    // 亮度：暗部减少色散，避免黑图中心出现 RGB 条纹
    float luminance = dot(float3(center.r, center.g, center.b), float3(0.299, 0.587, 0.114));
    float lightMask = smoothstep(0.08, 0.45, luminance);

    // 边缘才增强色散，中心保持稳定
    float edgeInfluence = smoothstep(0.50, 0.96, r);

    // 最终色散权重
    float chromaMask = edgeInfluence * mix(0.25, 1.0, lightMask);

    offset *= chromaMask;

    half4 shifted = layer.sample(position + offset);

    return half4(center.r, center.g, shifted.b, center.a);
}

[[ stitchable ]]
half4 orbRedShift(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float2 offset
) {
    float2 point = orbPoint(position, bounds);
    float r = length(point);

    half4 center = layer.sample(position);

    // 亮度控制，暗部减弱色散
    float luminance = dot(float3(center.r, center.g, center.b), float3(0.299, 0.587, 0.114));
    float lightMask = smoothstep(0.08, 0.45, luminance);

    // 边缘增强，中心稳定
    float edgeInfluence = smoothstep(0.50, 0.96, r);

    // 可以保留一点非对称，但不要让中心参与
    float leftBias = 1.0 - smoothstep(-0.75, 0.85, point.x);

    float chromaMask = edgeInfluence * mix(0.25, 1.0, lightMask);
    chromaMask *= mix(0.75, 1.15, leftBias);

    offset *= chromaMask;

    // 红蓝反方向取样，制造玻璃折射，但中心不动
    half4 shifted = layer.sample(position - offset);

    return half4(shifted.r, center.g, center.b, center.a);
}

// MARK: - Independent surface distortions

float2 inverseWaterUndulation(
    float2 point,
    float amount,
    float frequency,
    float phase,
    float2 direction
) {
    float2 primaryDirection = normalize(direction);
    float2 secondaryDirection = normalize(
        float2(-primaryDirection.y, primaryDirection.x) * 0.65
        + primaryDirection * 0.35
    );

    float primaryPhase = dot(point, primaryDirection) * frequency - phase;
    float secondaryPhase = dot(point, secondaryDirection)
        * frequency
        * 0.58
        + phase
        * 0.43
        + 1.40;

    // Refract along the gradient of two broad crossing wave fields. This gives
    // smooth water movement without circular rings or repeated embossed bands.
    float2 primaryGradient = primaryDirection
        * cos(primaryPhase)
        * frequency;
    float2 secondaryGradient = secondaryDirection
        * cos(secondaryPhase)
        * frequency
        * 0.58;
    float2 surfaceGradient = primaryGradient * 0.68
        + secondaryGradient * 0.32;

    float silhouetteFade = 1.0 - smoothstep(0.82, 1.0, length(point));
    float slowLift = 0.86
        + 0.14 * sin(point.y * 1.25 - phase * 0.12);
    float refractionStrength = amount * 0.115 * silhouetteFade * slowLift;
    return point - surfaceGradient * refractionStrength;
}

[[ stitchable ]]
half4 orbLowerLeftRipple(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float amount = 0.014,
    float frequency = 3.0,
    float phase = 1.8
) {
    float2 point = orbPoint(position, bounds);
    float2 sourcePoint = inverseWaterUndulation(
        point,
        amount,
        frequency,
        phase,
        normalize(float2(0.95, 0.15)
                  ));
    return layer.sample(orbPosition(sourcePoint, bounds));
}

[[ stitchable ]]
half4 orbPinch(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float strength
) {
    float2 point = orbPoint(position, bounds);
    float2 center = float2(0.02, -0.02);
    float pinchRadius = 1.80;
    float2 delta = point - center;
    float distanceFromCenter = length(delta);

    if (distanceFromCenter < 0.0001 || distanceFromCenter >= pinchRadius) {
        return layer.sample(position);
    }

    float normalizedDistance = distanceFromCenter / pinchRadius;
    float falloff = pow(1.0 - normalizedDistance, 2.0);
    float scale = max(0.18, 1.0 - strength * falloff * 0.58);
    float2 sourcePoint = center + delta * scale;
    return layer.sample(orbPosition(sourcePoint, bounds));
}

float diagonalWeight(float2 point) {
    // 假设 orbPoint 中：x 向右为正，y 向下为正
    // 右下角权重大，左上角权重小
    float2 axis = normalize(float2(1.0, 1.0));
    float t = clamp(0.5 + 0.5 * dot(point, axis), 0.0, 1.0);

    // 不要让左上完全没有，保留 35% 基础强度
    return mix(0.35, 1.0, smoothstep(0.08, 0.95, t));
}

[[ stitchable ]]
half4 orbRightDownRipple(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float amount = 0.012,
    float frequency = 1.2,
    float phase = 2.6
) {
    float2 point = orbPoint(position, bounds);

    float r = length(point);

    // 保持“珠子”感：中心稳，最外边缘也不要太破
    float ringMask = smoothstep(0.12, 0.40, r) * (1.0 - smoothstep(0.84, 1.0, r));

    // 右下强 → 左上弱，但左上也保留一点波动
    float diagMask = diagonalWeight(point);

    float localAmount = amount * ringMask * diagMask;

    // 不要偏移太大，保持浑圆
    float2 shift = float2(0.22, 0.14);
    float2 shiftedPoint = point - shift;

    float2 sourcePoint = inverseWaterUndulation(
        shiftedPoint,
        localAmount,
        frequency,
        phase + 0.65,
        normalize(float2(-0.82, -0.26))
    );

    // 前后用同一个 shift，保持对称
    sourcePoint += shift;

    return layer.sample(orbPosition(sourcePoint, bounds));
}

// MARK: - Vignette and exposure

[[ stitchable ]]
half4 orbVignette(
    float2 position,
    SwiftUI::Layer layer,
    float4 bounds,
    float amount,
    float size,
    float falloff
) {
    float radius = length(orbPoint(position, bounds));
    if (radius > 1.0) {
        return half4(0.0h);
    }

    half4 color = layer.sample(position);
    float fadeStart = clamp(size, 0.01, 0.99);
    float fadeEnd = clamp(fadeStart + falloff, fadeStart + 0.01, 1.20);
    float radialLight = 1.0 - smoothstep(fadeStart, fadeEnd, radius);
    float vignette = mix(1.0, radialLight, clamp(amount, 0.0, 1.0));

    // Keep color falloff soft, but make the physical silhouette clean.
    float edgeAlpha = 1.0 - smoothstep(0.955, 1.0, radius);
    half alpha = color.a * half(edgeAlpha);
    return half4(color.rgb * half(vignette) * alpha, alpha);
}

[[ stitchable ]]
half4 orbExposure(
    float2 position,
    half4 color,
    float exposure,
    float gamma,
    float gamutMap
) {
    if (color.a <= 0.0h) {
        return color;
    }

    float alpha = float(color.a);
    float3 straightColor = float3(color.rgb) / max(alpha, 0.0001);
    straightColor = max(straightColor, float3(0.0));
    straightColor *= exp2(exposure);
    straightColor = pow(straightColor, float3(1.0 / max(gamma, 0.01)));
    straightColor = straightColor
        / (float3(1.0) + straightColor * max(gamutMap, 0.0));
    return half4(half3(straightColor * alpha), color.a);
}
