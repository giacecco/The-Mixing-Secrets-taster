#!/bin/bash

# Absolute path to this script
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
PROCESSED_LOG="$SCRIPT_DIR/.processed_tracks.txt"

# Paths
SOURCE_DIR="${1:-/Volumes/home/music/multitracks/The Mixing Secrets}"
DESTINATION_FOLDER="/Users/giacecco/Music/Music/Media.localized/Automatically Add to Music.localized"
TEMP_DIR="$(mktemp -d "/tmp/mixing_secrets_XXXX")"

mkdir -p "$DESTINATION_FOLDER"
touch "$PROCESSED_LOG"
echo "📁 Temporary working dir: $TEMP_DIR"
echo "🗂 Using log file: $PROCESSED_LOG"

# Iterate over artist folders
for artist_dir in "$SOURCE_DIR"/*/; do
    artist_name="$(basename "$artist_dir")"

    for track_dir in "$artist_dir"*/; do
        track_name="$(basename "$track_dir")"
        preview_file="$track_dir/Full Preview mix.mp3"

        # Unique identifier per track
        track_key="${artist_name} - ${track_name}"

        # Skip if already processed
        if grep -Fxq "$track_key" "$PROCESSED_LOG"; then
            echo "⚠️ Skipped (already processed): $track_key"
            continue
        fi

        if [[ -f "$preview_file" ]]; then
            echo "🎚 Normalizing and tagging: $preview_file"

            temp_output="$TEMP_DIR/${track_key}.mp3"
            final_output="$DESTINATION_FOLDER/${track_key}.mp3"

            ffmpeg -hide_banner -y -i "$preview_file" \
                -af "loudnorm=I=-16:TP=-1.5:LRA=11" \
                -c:a libmp3lame -b:a 192k \
                -metadata album="The Mixing Secrets" \
                -metadata title="$track_name" \
                -metadata artist="$artist_name" \
                "$temp_output"

            if [[ -f "$temp_output" ]]; then
                temp_name="${final_output}.part"
                mv "$temp_output" "$temp_name" && mv "$temp_name" "$final_output"
                echo "$track_key" >> "$PROCESSED_LOG"
                echo "✅ Saved: $final_output"
            else
                echo "⚠️ Failed to process: $preview_file"
            fi
        else
            echo "❌ Missing: $preview_file"
        fi
    done
done

# Cleanup
rmdir "$TEMP_DIR" 2>/dev/null
echo "🎉 All done!"
