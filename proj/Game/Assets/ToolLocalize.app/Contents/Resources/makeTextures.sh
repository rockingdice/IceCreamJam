TP="/usr/local/bin/TexturePacker"
LOCALIZE_DIR="$1/textures/localized/"
UNIVERSE_DIR="$1/textures/universe/"
PNG_DIR="$1/textures/png/"
OUTPUT_LOCALIZE_DIR="$1/anims/_res/localized/"
OUTPUT_UNIVERSE_DIR="$1/anims/_res/universe/"
OUTPUT_LOCALIZE_RES="$1/res/localized/"
OUTPUT_UNIVERSE_RES="$1/res/universe/"
TAR_DIR="$1"

echo "building 1x png"
for File in $(find $PNG_DIR*.png -maxdepth 0)
do
FileName=${File##*/}
BaseName=${FileName%.*} 
${TP} \
--scale 0.25 \
--data "$OUTPUT_UNIVERSE_DIR"/1x/png/"$BaseName".plist \
--sheet "$OUTPUT_UNIVERSE_DIR"/1x/png/"$BaseName".png \
--size-constraints NPOT \
--shape-padding 0 \
--border-padding 0 \
--padding 0 \
--opt RGBA5551 \
"$File"
done

echo "building 2x png"
for File in $(find $PNG_DIR*.png -maxdepth 0)
do
FileName=${File##*/}
BaseName=${FileName%.*}
${TP} \
--scale 0.5 \
--data "$OUTPUT_UNIVERSE_DIR"/2x/png/"$BaseName".plist \
--sheet "$OUTPUT_UNIVERSE_DIR"/2x/png/"$BaseName".png \
--size-constraints NPOT \
--shape-padding 0 \
--border-padding 0 \
--padding 0 \
--opt RGBA5551 \
"$File"
done

echo "building 4x png"
for File in $(find $PNG_DIR*.png -maxdepth 0)
do
FileName=${File##*/}
BaseName=${FileName%.*}
${TP} \
--scale 1 \
--data "$OUTPUT_UNIVERSE_DIR"/4x/png/"$BaseName".plist \
--sheet "$OUTPUT_UNIVERSE_DIR"/4x/png/"$BaseName".png \
--size-constraints NPOT \
--shape-padding 0 \
--border-padding 0 \
--padding 0 \
--opt RGBA5551 \
"$File"
done



echo "building 0.5x png"
for File in $(find $PNG_DIR*.png -maxdepth 0)
do
FileName=${File##*/}
BaseName=${FileName%.*}
${TP} \
--scale 0.125 \
--data "$OUTPUT_UNIVERSE_RES"/0.5x/png/"$BaseName".plist \
--sheet "$OUTPUT_UNIVERSE_RES"/0.5x/png/"$BaseName".pvr.ccz \
--size-constraints NPOT \
--shape-padding 0 \
--border-padding 0 \
--padding 0 \
--opt RGBA5551 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$File"
done

echo "building 1x png"
for File in $(find $PNG_DIR*.png -maxdepth 0)
do
FileName=${File##*/}
BaseName=${FileName%.*}
${TP} \
--scale 0.25 \
--data "$OUTPUT_UNIVERSE_RES"/1x/png/"$BaseName".plist \
--sheet "$OUTPUT_UNIVERSE_RES"/1x/png/"$BaseName".pvr.ccz \
--size-constraints NPOT \
--shape-padding 0 \
--border-padding 0 \
--padding 0 \
--opt RGBA5551 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$File"
done

echo "building 2x png"
for File in $(find $PNG_DIR*.png -maxdepth 0)
do
FileName=${File##*/}
BaseName=${FileName%.*}
${TP} \
--scale 0.5 \
--data "$OUTPUT_UNIVERSE_RES"/2x/png/"$BaseName".plist \
--sheet "$OUTPUT_UNIVERSE_RES"/2x/png/"$BaseName".pvr.ccz \
--size-constraints NPOT \
--shape-padding 0 \
--border-padding 0 \
--padding 0 \
--opt RGBA5551 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$File"
done

echo "building 4x png"
for File in $(find $PNG_DIR*.png -maxdepth 0)
do
FileName=${File##*/}
BaseName=${FileName%.*}
${TP} \
--scale 1 \
--data "$OUTPUT_UNIVERSE_RES"/4x/png/"$BaseName".plist \
--sheet "$OUTPUT_UNIVERSE_RES"/4x/png/"$BaseName".pvr.ccz \
--size-constraints NPOT \
--shape-padding 0 \
--border-padding 0 \
--padding 0 \
--opt RGBA5551 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$File"
done


echo "building universe 1x png"
for Dir in $(find $UNIVERSE_DIR* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 0.25 \
--data  "$OUTPUT_UNIVERSE_DIR"/1x/"$DirName".plist \
--sheet "$OUTPUT_UNIVERSE_DIR"/1x/"$DirName".png \
--max-width 1024 \
--max-height 1024 \
"$Dir".tps
done

echo "building universe 2x png"
for Dir in $(find $UNIVERSE_DIR* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 0.5 \
--data  "$OUTPUT_UNIVERSE_DIR"/2x/"$DirName".plist \
--sheet "$OUTPUT_UNIVERSE_DIR"/2x/"$DirName".png \
--max-width 2048 \
--max-height 2048 \
"$Dir".tps
done

echo "building universe 4x png"
for Dir in $(find $UNIVERSE_DIR* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 1 \
--data  "$OUTPUT_UNIVERSE_DIR"/4x/"$DirName".plist \
--sheet "$OUTPUT_UNIVERSE_DIR"/4x/"$DirName".png \
--max-width 4096 \
--max-height 4096 \
"$Dir".tps
done


echo "building universe 0.5x pvr.ccz"
for Dir in $(find $UNIVERSE_DIR* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 0.125 \
--premultiply-alpha \
--data  "$OUTPUT_UNIVERSE_RES"/0.5x/"$DirName".plist \
--sheet "$OUTPUT_UNIVERSE_RES"/0.5x/"$DirName".pvr.ccz \
--max-width 512 \
--max-height 512 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$Dir".tps
done

echo "building universe 1x pvr.ccz"
for Dir in $(find $UNIVERSE_DIR* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 0.25 \
--premultiply-alpha \
--data  "$OUTPUT_UNIVERSE_RES"/1x/"$DirName".plist \
--sheet "$OUTPUT_UNIVERSE_RES"/1x/"$DirName".pvr.ccz \
--max-width 1024 \
--max-height 1024 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$Dir".tps
done

echo "building universe 2x pvr.ccz"
for Dir in $(find $UNIVERSE_DIR* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 0.5 \
--premultiply-alpha \
--data  "$OUTPUT_UNIVERSE_RES"/2x/"$DirName".plist \
--sheet "$OUTPUT_UNIVERSE_RES"/2x/"$DirName".pvr.ccz \
--max-width 2048 \
--max-height 2048 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$Dir".tps
done

echo "building universe 4x pvr.ccz"
for Dir in $(find $UNIVERSE_DIR* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 1 \
--premultiply-alpha \
--data  "$OUTPUT_UNIVERSE_RES"/4x/"$DirName".plist \
--sheet "$OUTPUT_UNIVERSE_RES"/4x/"$DirName".pvr.ccz \
--max-width 4096 \
--max-height 4096 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$Dir".tps
done


#new added localized by folders
for lName in $(find $LOCALIZE_DIR* -maxdepth 0 -type d )
do
fName=${lName##*/}
echo "building localized 1x png"
for Dir in $(find $LOCALIZE_DIR$fName/* -maxdepth 0 -type d )
do
echo $Dir
DirName=${Dir##*/}
${TP} \
--scale 0.25 \
--data  "$OUTPUT_LOCALIZE_DIR"/1x/"$DirName"/"$fName".plist \
--sheet "$OUTPUT_LOCALIZE_DIR"/1x/"$DirName"/"$fName".png \
--max-width 1024 \
--max-height 1024 \
"$Dir".tps
done

echo "building localized 2x png"
for Dir in $(find $LOCALIZE_DIR$fName/* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 0.5 \
--data  "$OUTPUT_LOCALIZE_DIR"/2x/"$DirName"/"$fName".plist \
--sheet "$OUTPUT_LOCALIZE_DIR"/2x/"$DirName"/"$fName".png \
--max-width 2048 \
--max-height 2048 \
"$Dir".tps
done

echo "building localized 4x png"
for Dir in $(find $LOCALIZE_DIR$fName/* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 1 \
--data  "$OUTPUT_LOCALIZE_DIR"/4x/"$DirName"/"$fName".plist \
--sheet "$OUTPUT_LOCALIZE_DIR"/4x/"$DirName"/"$fName".png \
--max-width 4096 \
--max-height 4096 \
"$Dir".tps
done

echo "building localized 0.5x pvr.ccz"
for Dir in $(find $LOCALIZE_DIR$fName/* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 0.125 \
--premultiply-alpha \
--data  "$OUTPUT_LOCALIZE_RES"/0.5x/"$DirName"/"$fName".plist \
--sheet "$OUTPUT_LOCALIZE_RES"/0.5x/"$DirName"/"$fName".pvr.ccz \
--max-width 512 \
--max-height 512 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$Dir".tps
done

echo "building localized 1x pvr.ccz"
for Dir in $(find $LOCALIZE_DIR$fName/* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 0.25 \
--premultiply-alpha \
--data  "$OUTPUT_LOCALIZE_RES"/1x/"$DirName"/"$fName".plist \
--sheet "$OUTPUT_LOCALIZE_RES"/1x/"$DirName"/"$fName".pvr.ccz \
--max-width 1024 \
--max-height 1024 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$Dir".tps
done

echo "building localized 2x pvr.ccz"
for Dir in $(find $LOCALIZE_DIR$fName/* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 0.5 \
--premultiply-alpha \
--data  "$OUTPUT_LOCALIZE_RES"/2x/"$DirName"/"$fName".plist \
--sheet "$OUTPUT_LOCALIZE_RES"/2x/"$DirName"/"$fName".pvr.ccz \
--max-width 2048 \
--max-height 2048 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$Dir".tps
done

echo "building localized 4x pvr.ccz"
for Dir in $(find $LOCALIZE_DIR$fName/* -maxdepth 0 -type d )
do
DirName=${Dir##*/}
${TP} \
--scale 1 \
--premultiply-alpha \
--data  "$OUTPUT_LOCALIZE_RES"/4x/"$DirName"/"$fName".plist \
--sheet "$OUTPUT_LOCALIZE_RES"/4x/"$DirName"/"$fName".pvr.ccz \
--max-width 4096 \
--max-height 4096 \
--content-protection 227f5ae3a9224580eb7796fa43a74754 \
"$Dir".tps
done

done
