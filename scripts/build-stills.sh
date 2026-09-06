#!/usr/bin/env bash
# Extract each mockup photo as a HIGH-QUALITY still (no video encoder, no denoise
# roundtrip). The site animates these with GPU CSS transforms, which is smoother than
# any encoded Ken Burns and skips H.264 compression blur. Quality is still capped by
# the 729px source, but this is the sharpest that source allows: one clean 2-step
# lanczos upscale + a light unsharp, no hqdn3d softening.
set -euo pipefail

FF="/c/Users/HP/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0-full_build/bin/ffmpeg.exe"
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/mockup.png"
IMG="$HERE/../assets/img"
mkdir -p "$IMG"

# still name cw ch cx cy delogo targetWidth [sharp]
still() {
  local name=$1 cw=$2 ch=$3 cx=$4 cy=$5 delogo=$6 tw=$7 sharp=${8:-0.7}
  local dl=""; [ -n "$delogo" ] && dl="${delogo},"
  "$FF" -y -v error -i "$SRC" -vf "\
crop=${cw}:${ch}:${cx}:${cy},\
${dl}\
scale=iw*2:ih*2:flags=lanczos+accurate_rnd,\
scale=${tw}:-2:flags=lanczos+accurate_rnd,\
unsharp=5:5:${sharp}:5:5:0.0,\
eq=contrast=1.03:saturation=1.05" \
    -q:v 2 "$IMG/${name}.jpg"
  printf '  %-16s %4dx%-4d -> w%-4d  %s\n' "$name" "$cw" "$ch" "$tw" "$(du -h "$IMG/${name}.jpg"|cut -f1)"
}

echo "Rendering high-quality stills for CSS motion..."

HERO_DELOGO="delogo=x=24:y=134:w=196:h=20,delogo=x=24:y=155:w=298:h=95,delogo=x=20:y=250:w=232:h=22,delogo=x=22:y=285:w=282:h=42,delogo=x=22:y=333:w=184:h=40,delogo=x=588:y=249:w=80:h=70,delogo=x=592:y=333:w=115:h=40,delogo=x=20:y=408:w=62:h=32,delogo=x=302:y=414:w=124:h=16"
still hero        729 443 0   48   "$HERO_DELOGO" 1600 0.6
still hero-mobile 729 443 0   48   "$HERO_DELOGO" 900  0.6

still about-villa 330 186 365 618  "" 1100 0.8

ICON="delogo=x=2:y=56:w=22:h=22"
still sol-residential  119 80 33  1027 "$ICON" 520 1.0
still sol-commercial   119 80 168 1027 "$ICON" 520 1.0
still sol-industrial   119 80 304 1027 "$ICON" 520 1.0
still sol-agricultural 119 80 439 1027 "$ICON" 520 1.0
still sol-hybrid       119 80 574 1027 "$ICON" 520 1.0

still calculator 389 143 340 1191 "delogo=x=275:y=25:w=90:h=42" 1600 0.9
still engineer   322 164 14  1611 "delogo=x=8:y=112:w=122:h=46" 1280 0.8
still cta        309 121 420 1820 "delogo=x=118:y=15:w=157:h=54,delogo=x=148:y=70:w=92:h=28" 1600 0.9

# faces + footer map (unchanged, small crisp crops)
face() { "$FF" -y -v error -i "$SRC" -vf "crop=$2:$3:$4:$5,scale=iw*4:ih*4:flags=lanczos,unsharp=3:3:0.5" "$IMG/$1.png"; }
face avatar-1   19 19 29  392
face avatar-2   19 19 47  392
face avatar-3   19 19 64  392
face portrait-1 30 30 389 1737
"$FF" -y -v error -i "$SRC" -vf "crop=136:87:562:1978,scale=iw*2:ih*2:flags=lanczos,unsharp=3:3:0.4" "$IMG/map.png"
echo "  faces + map            -> assets/img/*.png"

echo "Done -> assets/img/*.jpg"
