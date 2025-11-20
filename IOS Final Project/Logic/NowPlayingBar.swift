import SwiftUI

public struct NowPlayingBar: View {
    // Content
    public var title: String
    public var subtitle: String?
    public var artwork: Image?

    // Playback state
    @Binding public var isPlaying: Bool
    @Binding public var progress: Double // 0.0 ... 1.0

    // Actions
    public var onPlayPause: () -> Void
    public var onNext: () -> Void
    public var onTapBar: () -> Void

    // Appearance
    public var showsProgress: Bool

    public init(
        title: String,
        subtitle: String? = nil,
        artwork: Image? = nil,
        isPlaying: Binding<Bool>,
        progress: Binding<Double>,
        showsProgress: Bool = true,
        onPlayPause: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onTapBar: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.artwork = artwork
        self._isPlaying = isPlaying
        self._progress = progress
        self.onPlayPause = onPlayPause
        self.onNext = onNext
        self.onTapBar = onTapBar
        self.showsProgress = showsProgress
    }

    public var body: some View {
        VStack(spacing: 0) {
            if showsProgress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            HStack(spacing: 12) {
                // Artwork
                if let artwork {
                    artwork
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .accessibilityHidden(true)
                } else {
                    // Placeholder
                    Image(systemName: "music.note")
                        .frame(width: 44, height: 44)
                        .foregroundStyle(.secondary)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(.quaternary)
                        )
                        .accessibilityHidden(true)
                }

                // Title & subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { onTapBar() }

                Spacer(minLength: 8)

                // Controls
                HStack(spacing: 14) {
                    Button(action: onPlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .contentTransition(.symbolEffect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPlaying ? "Pause" : "Play")

                    Button(action: onNext) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Next")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -2)
        .padding(.horizontal)
        .padding(.bottom, safeAreaBottomPadding + 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var parts: [String] = [title]
        if let subtitle, !subtitle.isEmpty { parts.append(subtitle) }
        parts.append(isPlaying ? "Playing" : "Paused")
        return parts.joined(separator: ", ")
    }

    private var safeAreaBottomPadding: CGFloat {
        #if os(iOS)
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
        #else
        0
        #endif
    }
}

// MARK: - Preview

private struct NowPlayingBarPreviewHost: View {
    @State private var isPlaying = true
    @State private var progress: Double = 0.35

    var body: some View {
        ZStack(alignment: .bottom) {
            List(0..<20) { i in
                Text("Item \(i)")
            }

            NowPlayingBar(
                title: "Song Title",
                subtitle: "Artist Name",
                artwork: Image(systemName: "music.note.list"),
                isPlaying: $isPlaying,
                progress: $progress,
                onPlayPause: { isPlaying.toggle() },
                onNext: { progress = 0 },
                onTapBar: { print("Open full player") }
            )
        }
    }
}

#Preview("NowPlayingBar") {
    NowPlayingBarPreviewHost()
}
