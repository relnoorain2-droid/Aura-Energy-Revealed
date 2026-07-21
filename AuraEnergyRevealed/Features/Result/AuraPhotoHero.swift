//
//  AuraPhotoHero.swift
//  Aura Energy Revealed
//
//  The result hero: the user's ORIGINAL photo stays the focus, with
//  layered aura energy composed around them —
//    1. animated aura gradient field (behind)
//    2. blurred, tinted silhouette glow (Vision person segmentation)
//    3. the person cutout (or original photo when no person is found)
//    4. chakra points overlayed along the body's meridian
//  Never replaced by an avatar.
//

import SwiftUI

struct AuraPhotoHero: View {
    let reading: AuraReading
    var height: CGFloat = 340

    @State private var segmentation: SegmentationResult?
    @State private var auraBreathe = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var photo: UIImage? {
        reading.photoData.flatMap(UIImage.init(data:))
    }

    var body: some View {
        ZStack {
            // 1 · Animated aura field behind the person
            AuraOrbView(style: reading.dominant.orbStyle, size: height * 0.85, coreOpacity: 0.75)
                .blur(radius: 24)
                .scaleEffect(auraBreathe ? 1.06 : 0.98)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 5).repeatForever(autoreverses: true),
                    value: auraBreathe
                )

            if let photo {
                // 2 · Silhouette glow
                if let glow = segmentation?.auraGlow {
                    Image(uiImage: glow)
                        .resizable()
                        .scaledToFit()
                        .frame(height: height)
                        .opacity(auraBreathe ? 0.95 : 0.7)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 4).repeatForever(autoreverses: true),
                            value: auraBreathe
                        )
                        .blendMode(.screen)
                }

                // 3 · The person — cutout when possible, otherwise the photo
                //     itself with an aura rim
                Group {
                    if let cutout = segmentation?.personCutout {
                        Image(uiImage: cutout)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: height * 0.62, height: height * 0.78)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .strokeBorder(
                                        AngularGradient(colors: reading.dominant.orbStyle.colors + [reading.dominant.orbStyle.colors[0]], center: .center),
                                        lineWidth: 2.5
                                    )
                                    .blur(radius: 1)
                            }
                            .shadow(color: (reading.dominant.orbStyle.colors.first ?? .white).opacity(0.6), radius: 30)
                    }
                }
                .frame(height: height)

                // 4 · Chakra points along the meridian (self scans only)
                if reading.mode == .selfAura, segmentation?.personCutout != nil {
                    chakraOverlay
                }
            } else {
                // No photo stored (legacy reading) — living orb stands in
                AuraOrbView(style: reading.dominant.orbStyle, size: height * 0.55)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .task(id: reading.persistentModelID) {
            guard let photo, segmentation == nil else { return }
            let glowColor = UIColor(reading.dominant.orbStyle.colors.first ?? AuraPalette.lavender)
            segmentation = await PersonSegmentationService.process(image: photo, glowColor: glowColor)
        }
        .onAppear { auraBreathe = true }
        .accessibilityLabel("Your photo, surrounded by your \(reading.dominant.displayName) aura")
    }

    private var chakraOverlay: some View {
        VStack(spacing: height * 0.055) {
            ForEach(Chakra.sample(seed: reading.date.hashValue).prefix(5)) { chakra in
                Circle()
                    .fill(chakra.color)
                    .frame(width: 12, height: 12)
                    .shadow(color: chakra.color, radius: 8)
                    .scaleEffect(auraBreathe ? 1.15 : 1)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 3.4).repeatForever(autoreverses: true),
                        value: auraBreathe
                    )
            }
        }
        .offset(y: height * 0.02)
        .allowsHitTesting(false)
    }
}
