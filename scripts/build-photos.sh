#!/usr/bin/env bash
# Fetch genuinely high-resolution photos (Pexels, free/commercial licence, no
# attribution required) of the SAME scenes as the mockup, and fit each to its slot.
# This replaces the soft upscales that came from the 729px mockup crop.
set -euo pipefail

FF="/c/Users/HP/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe"
HERE="$(cd "$(dirname "$0")" && pwd)"
IMG="$HERE/../assets/img"
RAW="$HERE/../.raw"; mkdir -p "$RAW" "$IMG"
UA="Mozilla/5.0"

get() { # id -> RAW/<id>.jpg at width 1600
  local id=$1
  [ -s "$RAW/$id.jpg" ] || curl -sL -A "$UA" \
    "https://images.pexels.com/photos/$id/pexels-photo-$id.jpeg?auto=compress&cs=tinysrgb&w=3000" -o "$RAW/$id.jpg"
}

# fit id out W H sharpen [grade] [q]
# Sizes are 2x-DPI aware: full-width slots are ~2560px so they stay sharp on
# retina/high-DPI screens (a 1600px image blows up ~2x full-width and looks blurry).
fit() {
  local id=$1 out=$2 w=$3 h=$4 sharp=${5:-0.7} grade=${6:-} q=${7:-2}
  get "$id"
  local gf=""; [ -n "$grade" ] && gf=",$grade"
  "$FF" -y -v error -i "$RAW/$id.jpg" -vf \
"scale=${w}:${h}:force_original_aspect_ratio=increase:flags=lanczos+accurate_rnd,crop=${w}:${h},unsharp=5:5:${sharp}:5:5:0.0${gf}" \
    -q:v ${q} "$IMG/${out}.jpg"
  printf '  %-16s <- %-9s %dx%d  %s\n' "$out" "$id" "$w" "$h" "$(du -h "$IMG/${out}.jpg"|cut -f1)"
}

WARM="eq=contrast=1.06:saturation=1.12:gamma=0.97,colorbalance=rm=0.06:rs=0.04:bm=-0.06:bs=-0.05"
DUSK="eq=contrast=1.05:saturation=1.14:gamma=0.94:brightness=-0.02,colorbalance=rm=0.08:rs=0.05:bm=-0.07:bs=-0.06"

echo "Building high-res photos into slots..."
fit 27873610 hero        2560 1440 0.7 "$WARM" 3   # panel array + sky (warm-graded)
fit 27873610 hero-mobile 1400 788  0.7 "$WARM" 3
fit 33757669 about-villa 1600 1100 0.8 "" 3        # house with rooftop solar
fit 19344325 sol-residential  900 675 0.8 "" 3     # modern home
fit 12446411 sol-commercial   900 675 0.8 "eq=contrast=1.05:saturation=1.08" 3  # business district
fit 27637329 sol-industrial   900 675 0.8 "" 3     # large-scale solar farm
fit 32408717 sol-agricultural 900 675 0.8 "" 3     # fields + wind
fit 9799743  sol-hybrid       900 675 0.8 "" 3     # battery / EV charging
fit 21923152 calculator  2560 1440 0.6 "$DUSK" 4   # Rajasthan fort (dusk-graded)
fit 34526423 engineer    1920 1080 0.6 "" 3        # technician at work
fit 8853509  cta         2560 1440 0.5 "$WARM" 4   # sharp panel macro (warm)

cat > "$IMG/CREDITS.txt" <<'EOF'
Photos: Pexels (Pexels License — free for commercial use, no attribution required).
hero/hero-mobile pexels.com/photo/27873610  about-villa 33757669  residential 19344325
commercial 12446411  industrial 27637329  agricultural 32408717  hybrid 9799743
calculator 21923152  engineer 34526423  cta 8853509
EOF
echo "Done -> assets/img/*.jpg"
