GDCL="/usr/local/bin/GDCL"
LOCALIZE_DIR="$1/fonts/localized/"
UNIVERSE_DIR="$1/fonts/universe/"
OUTPUT_LOCALIZE_DIR="$1/anims/_res/localized/"
OUTPUT_UNIVERSE_DIR="$1/anims/_res/universe/"
OUTPUT_LOCALIZE_RES="$1/res/localized/"
OUTPUT_UNIVERSE_RES="$1/res/universe/"
TAR_DIR="$1"

echo "building universe 1x font editor"
for Dir in $(find $UNIVERSE_DIR*.GlyphProject -maxdepth 0);
do
DirName=${Dir##*/}
FULLNAME=$Dir
FILENAME=${DirName%.*}

${GDCL} \
$UNIVERSE_DIR$FILENAME \
$OUTPUT_UNIVERSE_DIR"1x/"$FILENAME \
-rfs 0.25
echo $OUTPUT_UNIVERSE_DIR"1x/"$FILENAME "done."

done

echo "building universe 2x font editor"
for Dir in $(find $UNIVERSE_DIR*.GlyphProject -maxdepth 0);
do
DirName=${Dir##*/}
FULLNAME=$Dir
FILENAME=${DirName%.*}

${GDCL} \
$UNIVERSE_DIR$FILENAME \
$OUTPUT_UNIVERSE_DIR"2x/"$FILENAME \
-rfs 0.5
echo $OUTPUT_UNIVERSE_DIR"2x/"$FILENAME "done."
done

echo "building universe 4x font editor"
for Dir in $(find $UNIVERSE_DIR*.GlyphProject -maxdepth 0);
do
DirName=${Dir##*/}
FULLNAME=$Dir
FILENAME=${DirName%.*}

${GDCL} \
$UNIVERSE_DIR$FILENAME \
$OUTPUT_UNIVERSE_DIR"4x/"$FILENAME
echo $OUTPUT_UNIVERSE_DIR"4x/"$FILENAME "done."
done


echo "building universe 0.5x font"
for Dir in $(find $UNIVERSE_DIR*.GlyphProject -maxdepth 0);
do
DirName=${Dir##*/}
FULLNAME=$Dir
FILENAME=${DirName%.*}

${GDCL} \
$UNIVERSE_DIR$FILENAME \
$OUTPUT_UNIVERSE_RES"0.5x/"$FILENAME \
-rfs 0.125
echo $OUTPUT_UNIVERSE_RES"0.5x/"$FILENAME "done."
done

echo "building universe 1x font"
for Dir in $(find $UNIVERSE_DIR*.GlyphProject -maxdepth 0);
do
DirName=${Dir##*/}
FULLNAME=$Dir
FILENAME=${DirName%.*}

${GDCL} \
$UNIVERSE_DIR$FILENAME \
$OUTPUT_UNIVERSE_RES"1x/"$FILENAME \
-rfs 0.25
echo $OUTPUT_UNIVERSE_RES"1x/"$FILENAME "done."
done


echo "building universe 2x font"
for Dir in $(find $UNIVERSE_DIR*.GlyphProject -maxdepth 0);
do
DirName=${Dir##*/}
FULLNAME=$Dir
FILENAME=${DirName%.*}

${GDCL} \
$UNIVERSE_DIR$FILENAME \
$OUTPUT_UNIVERSE_RES"2x/"$FILENAME \
-rfs 0.5
echo $OUTPUT_UNIVERSE_RES"2x/"$FILENAME "done."
done


echo "building universe 4x font"
for Dir in $(find $UNIVERSE_DIR*.GlyphProject -maxdepth 0);
do
DirName=${Dir##*/}
FULLNAME=$Dir
FILENAME=${DirName%.*}

${GDCL} \
$UNIVERSE_DIR$FILENAME \
$OUTPUT_UNIVERSE_RES"4x/"$FILENAME
echo $OUTPUT_UNIVERSE_RES"4x/"$FILENAME "done."
done
