#!/usr/bin/env bash
# Extracts the mockup's own photos and renders each as a 720p video.
#   crop    : the photo's rect inside mockup.png
#   delogo  : rects of baked-in mockup text, interpolated away (the site draws real text)
#   quality : denoise -> gradual lanczos upscale -> contrast-adaptive sharpen, no added grain
#   motion  : a slow ping-pong zoom rendered over a 3840x2160 oversampled canvas, then
#             downscaled to 720p. At that scale every motion step is ~0.3 output px, i.e.
#             sub-pixel, so the pan/zoom glides instead of stair-stepping 1px at a time
#             (the judder you get panning a dynamic ffmpeg crop). zoompan needs a big input
#             or it jitters; the 3x oversample is exactly that fix.
set -euo pipefail

FF="/c/Users/HP/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe"
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/mockup.png"
OUT="$HERE/../assets/video"
IMG="$HERE/../assets/img"
mkdir -p "$OUT" "$IMG"

DUR=20            # long loop = slow, calm motion
FPS=30
OS=3              # oversample: canvas = OS x the output so every motion step is sub-pixel
T=$((DUR*FPS))    # total frames
Z0=1.04           # baseline zoom: always >1 so there is crop slack for the drift
AMP=0.06          # ping-pong zoom depth (z travels Z0 .. Z0+AMP .. Z0)

# render name cw ch cx cy delogo [mode] [ow] [oh] [crf]
# ow/oh default to 720p for full-width media; small cards pass 640x360 (they display ~200px,
# so 720p there is wasted bytes). crf 20 is visually identical to 18 at these sizes.
render() {
  local name=$1 cw=$2 ch=$3 cx=$4 cy=$5 delogo=$6 mode=${7:-in} ow=${8:-1280} oh=${9:-720} crf=${10:-20}
  local dl=""; [ -n "$delogo" ] && dl="${delogo},"
  local CW=$((ow*OS)) CH=$((oh*OS))

  # pp: smooth 0 -> 1 -> 0 over the loop (cosine ease, seamless at the seam)
  local pp="(0.5-0.5*cos(2*PI*on/${T}))"
  local z
  if [ "$mode" = out ]; then z="${Z0}+${AMP}*(1-${pp})"; else z="${Z0}+${AMP}*${pp}"; fi
  # centred zoom + a tiny drift (<=1.2% w, 0.6% h) that shares pp, so it stays in lockstep
  local zx="(iw-iw/zoom)/2+(iw*0.012)*(2*${pp}-1)"
  local zy="(ih-ih/zoom)/2+(ih*0.006)*(2*${pp}-1)"

  "$FF" -y -v error -i "$SRC" -filter_complex "\
crop=${cw}:${ch}:${cx}:${cy},\
${dl}\
hqdn3d=2.5:2:6:5,\
scale=iw*2:ih*2:flags=lanczos,\
scale=${CW}:${CH}:force_original_aspect_ratio=increase:flags=lanczos,\
crop=${CW}:${CH},setsar=1,\
zoompan=z='${z}':x='${zx}':y='${zy}':d=${T}:s=${ow}x${oh}:fps=${FPS},\
cas=0.62,\
format=yuv420p" \
    -frames:v "$T" -r "$FPS" -c:v libx264 -crf "$crf" -preset veryslow -tune film \
    -profile:v high -level 4.0 -movflags +faststart -an "$OUT/${name}.mp4"

  # poster frame (mid-loop) for <video poster> / reduced-motion
  "$FF" -y -v error -i "$OUT/${name}.mp4" -ss $((DUR/2)) -frames:v 1 -q:v 2 "$IMG/${name}.jpg"

  printf '  %-22s %4dx%-4d -> %dx%d  zoom %-3s  %s\n' \
    "$name" "$cw" "$ch" "$ow" "$oh" "$mode" "$(du -h "$OUT/${name}.mp4" | cut -f1)"
}

echo "Rendering 720p video from mockup photos (oversampled zoompan)..."

HERO_DELOGO="delogo=x=24:y=134:w=196:h=20,delogo=x=24:y=155:w=298:h=95,delogo=x=20:y=250:w=232:h=22,delogo=x=22:y=285:w=282:h=42,delogo=x=22:y=333:w=184:h=40,delogo=x=588:y=249:w=80:h=70,delogo=x=592:y=333:w=115:h=40,delogo=x=20:y=408:w=62:h=32,delogo=x=302:y=414:w=124:h=16"
render hero        729 443 0 48 "$HERO_DELOGO" out
# lighter hero for phones (same framing, ~half the bytes on cellular)
render hero-mobile 729 443 0 48 "$HERO_DELOGO" out 768 432 22

render about-villa 330 186 365 618 "" in

# 4px inset keeps the card's own rounded border out of the frame.
# cards display ~200px wide, so render at 640x360 to keep them light
ICON="delogo=x=2:y=56:w=22:h=22"
render sol-residential  119 80 33  1027 "$ICON" in  640 360 21
render sol-commercial   119 80 168 1027 "$ICON" out 640 360 21
render sol-industrial   119 80 304 1027 "$ICON" in  640 360 21
render sol-agricultural 119 80 439 1027 "$ICON" out 640 360 21
render sol-hybrid       119 80 574 1027 "$ICON" in  640 360 21

# the fort occupies the right half; stay right of the heading and above the form row
render calculator 389 143 340 1191 \
"delogo=x=275:y=25:w=90:h=42" out

render engineer 322 164 14 1611 \
"delogo=x=8:y=112:w=122:h=46" in

# panels + sun sit right of the headline; start the crop past it
render cta 309 121 420 1820 \
"delogo=x=118:y=15:w=157:h=54,delogo=x=148:y=70:w=92:h=28" out

# --- stills: faces and the footer map, lifted straight from the mockup ---
still() { # name cw ch cx cy scale
  "$FF" -y -v error -i "$SRC" \
    -vf "crop=$2:$3:$4:$5,hqdn3d=2:1.5:5:4,scale=iw*2:ih*2:flags=lanczos,scale=iw*$6:ih*$6:flags=lanczos,cas=0.5" \
    "$IMG/$1.png"
}
still avatar-1   19 19 29  392 4
still avatar-2   19 19 47  392 4
still avatar-3   19 19 64  392 4
still portrait-1 30 30 389 1737 4
still map        136 87 562 1978 2
echo "  stills                 -> assets/img/*.png"

echo "Done -> assets/video/*.mp4  +  assets/img/ posters & stills"
