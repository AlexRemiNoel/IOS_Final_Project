public import SwiftUI

public struct PlaybackControls: View {
    // Public callbacks to wire up actions from host view
    public var onPlayPlaylist: () -> Void
    public var onPlaySong: () -> Void

    // Optional state controls
    public var isPlaylistActionDisabled: Bool
    public var isSongActionDisabled: Bool
    public var isPlaylistLoading: Bool
    public var isSongLoading: Bool

    public init(
        onPlayPlaylist: @escaping () -> Void,
        onPlaySong: @escaping () -> Void,
        isPlaylistActionDisabled: Bool = false,
        isSongActionDisabled: Bool = false,
        isPlaylistLoading: Bool = false,
        isSongLoading: Bool = false
    ) {
        self.onPlayPlaylist = onPlayPlaylist
        self.onPlaySong = onPlaySong
        self.isPlaylistActionDisabled = isPlaylistActionDisabled
        self.isSongActionDisabled = isSongActionDisabled
        self.isPlaylistLoading = isPlaylistLoading
        self.isSongLoading = isSongLoading
    }

    public var body: some View {
        HStack(spacing: 16) {
            Button(action: onPlayPlaylist) {
                HStack(spacing: 8) {
                    if isPlaylistLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "play.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                    Text("Play Playlist")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .disabled(isPlaylistActionDisabled || isPlaylistLoading)

            Button(action: onPlaySong) {
                HStack(spacing: 8) {
                    if isSongLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
                    } else {
                        // A distinct icon for single-song play
                        Image(systemName: "music.note.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                    Text("Play Song")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryPillButtonStyle())
            .disabled(isSongActionDisabled || isSongLoading)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Button Styles

struct PrimaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                Capsule().fill(Color.accentColor)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.tint)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                Capsule().fill(Color.accentColor.opacity(0.12))
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("PlaybackControls") {
    VStack(spacing: 24) {
        PlaybackControls(
            onPlayPlaylist: { print("Play playlist tapped") },
            onPlaySong: { print("Play song tapped") },
            isPlaylistActionDisabled: false,
            isSongActionDisabled: false,
            isPlaylistLoading: false,
            isSongLoading: false
        )

        PlaybackControls(
            onPlayPlaylist: {},
            onPlaySong: {},
            isPlaylistActionDisabled: true,
            isSongActionDisabled: false,
            isPlaylistLoading: true,
            isSongLoading: false
        )
    }
    .padding()
}
