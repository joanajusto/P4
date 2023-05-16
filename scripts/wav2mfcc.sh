#!/bin/bash

## \file
## \TODO This file implements a very trivial feature extraction; use it as a template for other front ends.
## 
## Please, read SPTK documentation and some papers in order to implement more advanced front ends.

# Base name for temporary files
base=/tmp/$(basename $0).$$ 

# Ensure cleanup of temporary files on exit
trap cleanup EXIT
cleanup() {
   \rm -f $base.*
}

if [[ $# != 4 ]]; then
   echo "$0 mfcc_order mfcc_nfilter input.wav output.mfcc"
   exit 1
fi

mfcc_order=$1
mfcc_nfilter=$2
inputfile=$3
outputfile=$4

UBUNTU_SPTK=1
if [[ $UBUNTU_SPTK == 1 ]]; then
   # In case you install SPTK using debian package (apt-get)
   X2X="sptk x2x"
   FRAME="sptk frame"
   WINDOW="sptk window"
   MFCC="sptk mfcc"
else
   # or install SPTK building it from its source
   X2X="x2x"
   FRAME="frame"
   WINDOW="window"
   MFCC="mfcc"
fi

# Main command for feature extration
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	$MFCC -l 240 -s 8 -w 1 -m $mfcc_order -n $mfcc_nfilter > $base.mfcc

# Our array files need a header with the number of cols and rows:
ncol=$mfcc_order # mfcc p =>  (c0 c1 c2 ... cp-1) 
nrow=`$X2X +fa < $base.mfcc | wc -l | perl -ne 'print $_/'$ncol', "\n";'`

# Build fmatrix file by placing nrow and ncol in front, and the data after them
echo $nrow $ncol | $X2X +aI > $outputfile
cat $base.mfcc >> $outputfile

exit