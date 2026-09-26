//
//  FloatingTabBar.swift
//  Aura Energy Revealed
//
//  Five-item glass tab bar; the center slot is the Scan action — a glowing
//  aura orb floating above the bar, pulsing on a calm 4s cadence.
//  Long-press the orb for the scan-type menu, per the navigation spec.
//

import SwiftUI

struct FloatingTabBar: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreService.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var orbPulse = false

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.explore)
            scanOrb
                .frame(maxWidth: .infinity)
            tabButton(.practice)
            tabButton(.you)
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AuraPalette.deepSpace.opacity(0.55))
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(AuraPalette.hairline, lineWidth: 1)
        }
        .padding(.horizontal, AuraSpacing.m)
        .padding(.bottom, AuraSpacing.m)
        .shadow(color: .black.opacity(0.55), radius: 24, y: 12)
    }

    // MARK: Tab item

    private func tabButton(_ tab: AppTab) -> some View {
        let isOn = appState.selectedTab == tab
        return Button {
            Haptics.selection()
            withAnimation(AuraMotion.micro) {
                appState.selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.symbol)
                    .symbolVariant(isOn ? .fill : .none)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 30, height: 30)
                    .background {
                        if isOn {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(AuraPalette.electricBlue.opacity(0.16))
                        }
                    }
                Text(tab.title)
                    .font(AuraFont.text(10, weight: .medium))
            }
            .foregroundStyle(isOn ? AuraPalette.ink : AuraPalette.ink.opacity(0.4))
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }

    // MARK: Scan orb — the app's heartbeat

    private var scanOrb: some View {
        Button {
            Haptics.impactSoft()
            appState.isScanFlowPresented = true
        } label: {
            ZStack {
                Circle()
                    .fill(AngularGradient(colors: AuraPalette.spectrum, center: .center))
                    .frame(width: 62, height: 62)
                    .shadow(
                        color: AuraPalette.auroraPurpleDeep.opacity(orbPulse ? 0.85 : 0.55),
                        radius: orbPulse ? 24 : 13
                    )
                Circle()
                    .fill(Color(hex: 0x0D0D16))
                    .frame(width: 52, height: 52)
                Image(systemName: "sparkle")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .offset(y: -18)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                orbPulse = true
            }
        }
        .contextMenu {
            ForEach(ScanMode.allCases) { mode in
                Button {
                    appState.isScanFlowPresented = true
                } label: {
                    Label(mode.title, systemImage: mode.symbol)
                }
            }
        }
        .accessibilityLabel("Scan your aura")
    }
}
