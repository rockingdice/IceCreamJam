LANG=zh_CN.UTF-8
GDCL="/usr/local/bin/GDCL"
LOCALIZE_DIR="$1/fonts/localized/"
OUTPUT_LOCALIZE_DIR="$1/anims/_res/localized/"
OUTPUT_LOCALIZE_RES="$1/res/localized/"
TAR_DIR="$1"
LANG_STR="$2"
FONT_ID="$3"
INPUT_FILE="$4"
echo $INPUT_FILE

echo "building localized font for language:" $LANG_STR " font_id:" $FONT_ID
Dir=$LOCALIZE_DIR$LANG_STR"/font_"$FONT_ID
${GDCL} \
$Dir \
$OUTPUT_LOCALIZE_RES"0.5x/"$LANG_STR"/font_"$FONT_ID \
-rfs 0.125 \
-inf $INPUT_FILE
echo $OUTPUT_LOCALIZE_RES"0.5x/"$LANG_STR"/font_"$FONT_ID "done."

Dir=$LOCALIZE_DIR$LANG_STR"/font_"$FONT_ID
${GDCL} \
$Dir \
$OUTPUT_LOCALIZE_DIR"1x/"$LANG_STR"/font_"$FONT_ID \
-rfs 0.25 \
-inf $INPUT_FILE
echo $OUTPUT_LOCALIZE_DIR"1x/"$LANG_STR"/font_"$FONT_ID "done."

${GDCL} \
$Dir \
$OUTPUT_LOCALIZE_RES"1x/"$LANG_STR"/font_"$FONT_ID \
-rfs 0.25 \
-inf $INPUT_FILE
echo $OUTPUT_LOCALIZE_RES"1x/"$LANG_STR"/font_"$FONT_ID "done."

${GDCL} \
$Dir \
$OUTPUT_LOCALIZE_DIR"2x/"$LANG_STR"/font_"$FONT_ID \
-rfs 0.5 \
-inf $INPUT_FILE
echo $OUTPUT_LOCALIZE_DIR"2x/"$LANG_STR"/font_"$FONT_ID "done."

${GDCL} \
$Dir \
$OUTPUT_LOCALIZE_RES"2x/"$LANG_STR"/font_"$FONT_ID \
-rfs 0.5 \
-inf $INPUT_FILE
echo $OUTPUT_LOCALIZE_RES"2x/"$LANG_STR"/font_"$FONT_ID "done."

${GDCL} \
$Dir \
$OUTPUT_LOCALIZE_DIR"4x/"$LANG_STR"/font_"$FONT_ID \
-inf $INPUT_FILE
echo $OUTPUT_LOCALIZE_DIR"4x/"$LANG_STR"/font_"$FONT_ID "done."

${GDCL} \
$Dir \
$OUTPUT_LOCALIZE_RES"4x/"$LANG_STR"/font_"$FONT_ID \
-inf $INPUT_FILE
echo $OUTPUT_LOCALIZE_RES"4x/"$LANG_STR"/font_"$FONT_ID "done."

sleep 0.1
