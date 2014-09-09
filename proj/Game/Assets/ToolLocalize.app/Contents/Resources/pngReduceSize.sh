OUTPUT_LOCALIZE_RES="$1/res/localized/"
OUTPUT_UNIVERSE_RES="$1/res/universe/"
TAR_DIR="$1"
APP_DIR="$2"

echoerr() { echo "$@" 1>&2; }

FILETOTAL=0
FILEFINALTOTAL=0
echoerr "png reduce size for localized pngs"
for File in $(find $OUTPUT_LOCALIZE_RES* -type f -iname "*.png" -maxdepth 2);
do
FILETOTAL=$(expr $(stat -f "%z" $File) + $FILETOTAL)

${APP_DIR} \
-rem alla \
-reduce \
$File \
$File"_tmp"

mv $File"_tmp" $File

FILEFINALTOTAL=$(expr $(stat -f "%z" $File) + $FILEFINALTOTAL)
done


echoerr "png reduce size for universe pngs"
for File in $(find $OUTPUT_UNIVERSE_RES* -type f -iname "*.png" -maxdepth 2);
do
FILETOTAL=$(expr $(stat -f "%z" $File) + $FILETOTAL)

${APP_DIR} \
-rem alla \
-reduce \
$File \
$File"_tmp"

mv $File"_tmp" $File

FILEFINALTOTAL=$(expr $(stat -f "%z" $File) + $FILEFINALTOTAL)
done

REDUCED=$(expr $FILETOTAL - $FILEFINALTOTAL)
REDUCED=$(echo "scale=3;$REDUCED / 1048576" | bc -l)
echoerr save $REDUCED MB for pngs
sleep 0.1