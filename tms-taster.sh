#!/bin/bash

# Usage: ./script.sh [source_directory]
SOURCE_DIR="${1:-/Volumes/home/music/multitracks/The Mixing Secrets}"
DESTINATION_FOLDER="/Users/giacecco/Music/Music/Media.localized/Automatically Add to Music.localized"
TEMP_DIR="$(mktemp -d "/tmp/mixing_secrets_XXXX")"

mkdir -p "$DESTINATION_FOLDER"
echo "📁 Temporary working dir: $TEMP_DIR"

# Iterate over artist folders
for artist_dir in "$SOURCE_DIR"/*/; do
    artist_name="$(basename "$artist_dir")"

    # Iterate over track folders
    for track_dir in "$artist_dir"*/; do
        track_name="$(basename "$track_dir")"
        preview_file="$track_dir/Full Preview mix.mp3"

        if [[ -f "$preview_file" ]]; then
            echo "🎚 Normalizing and tagging: $preview_file"

            temp_output="$TEMP_DIR/${artist_name} - ${track_name}.mp3"
            final_output="$DESTINATION_FOLDER/${artist_name} - ${track_name}.mp3"

            ffmpeg -hide_banner -y -i "$preview_file" \
                -af "loudnorm=I=-16:TP=-1.5:LRA=11" \
                -c:a libmp3lame -b:a 192k \
                -metadata album="The Mixing Secrets" \
                -metadata title="$track_name" \
                -metadata artist="$artist_name" \
                "$temp_output"

            if [[ -f "$temp_output" ]]; then
                mv "$temp_output" "$final_output"
                echo "✅ Saved: $final_output"
            else
                echo "⚠️ Failed to process: $preview_file"
            fi
        else
            echo "❌ Missing: $preview_file"
        fi
    done
done

# Cleanup temp folder if empty
rmdir "$TEMP_DIR" 2>/dev/null

echo "🎉 All done!"
