//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// BatChat splash logo styled similarly to the Element X authentication logo.
struct OnboardingSplashLogo: View {
    @Environment(\.colorScheme) private var colorScheme
    
    /// Extra padding needed to avoid cropping the shadows.
    private let extra: CGFloat = 64
    /// The shape that the logo is composed on top of.
    private let outerShape = RoundedRectangle(cornerRadius: 44, style: .continuous)
    private let outerShapeShadowColor = Color(red: 0.11, green: 0.11, blue: 0.13)
    
    private var isLight: Bool {
        colorScheme == .light
    }
    
    var body: some View {
        brandLogo
    }
    
    private var brandLogo: some View {
        Image(Asset.Images.onboardingBatchat.name)
            .resizable()
            .frame(width: 100, height: 100)
            // Keep logo readable in dark mode.
            .brightness(isLight ? 0 : 0.25)
            .background {
                // Inner circular plate behind the logo.
                Circle()
                    .inset(by: 1)
                    .fill(isLight ? Color.white : Color.black.opacity(0.85))
                    .shadow(
                        color: .black.opacity(!isLight ? 0.3 : 0.4),
                        radius: 12.57143,
                        y: 6.28571
                    )
                
                Circle()
                    .inset(by: 1)
                    .fill(isLight ? Color.white : Color.black.opacity(0.85))
                    .shadow(
                        color: .black.opacity(0.5),
                        radius: 12.57143,
                        y: 6.28571
                    )
                    .blendMode(.overlay)
            }
            .padding(24)
            .background {
                if isLight {
                    Color.white
                } else {
                    Color.black.opacity(0.85)
                }
            }
            .clipShape(outerShape)
            .overlay {
                outerShape
                    .inset(by: 0.25)
                    .stroke(
                        isLight ? .white.opacity(1) : .white.opacity(0.9),
                        lineWidth: 0.5
                    )
                    .blendMode(isLight ? .normal : .overlay)
            }
            .padding(extra)
            .background {
                ZStack {
                    if !isLight {
                        outerShape
                            .inset(by: 1)
                            .padding(extra)
                            .shadow(
                                color: .black.opacity(0.5),
                                radius: 32.91666,
                                y: 1.05333
                            )
                    } else {
                        outerShape
                            .inset(by: 1)
                            .padding(extra)
                            .shadow(
                                color: outerShapeShadowColor.opacity(0.23),
                                radius: 16,
                                y: 8
                            )
                        
                        outerShape
                            .inset(by: 1)
                            .padding(extra)
                            .shadow(
                                color: outerShapeShadowColor.opacity(0.5),
                                radius: 16,
                                y: 8
                            )
                            .blendMode(.overlay)
                    }
                }
                .mask {
                    outerShape
                        .inset(by: -extra / 2)
                        .stroke(lineWidth: extra)
                        .padding(extra)
                }
            }
            .padding(-extra)
            .accessibilityHidden(true)
    }
}

struct OnboardingSplashScreenPage: View {
    // MARK: - Properties
    
    // MARK: Private

    @Environment(\.theme) private var theme
    
    // MARK: Public

    /// The content that this page should display.
    let content: OnboardingSplashScreenPageContent
    
    // MARK: - Views
    
    var body: some View {
        VStack {
            OnboardingSplashLogo()
                .frame(maxWidth: 310)
                .padding(.bottom, 16)
            
            VStack(spacing: 8) {
                OnboardingTintedFullStopText(content.title)
                    .font(theme.fonts.title2B)
                    .foregroundColor(theme.colors.primaryContent)
                Text(content.message)
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.secondaryContent)
                    .multilineTextAlignment(.center)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom)
        .padding(.horizontal, 16)
        .readableFrame()
    }
}

struct OnboardingSplashScreenPage_Previews: PreviewProvider {
    static let content = OnboardingSplashScreenViewState().content
    static var previews: some View {
        ForEach(0..<content.count, id: \.self) { index in
            OnboardingSplashScreenPage(content: content[index])
        }
    }
}
