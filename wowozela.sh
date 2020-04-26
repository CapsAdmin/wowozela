#!/bin/bash

WORKSHOP_ID=108170491

if [[ "$OSTYPE" == "darwin"* ]]; then
    suffix="osx"
else 
    suffix="linux"
fi

../../../bin/gmad_$suffix create -folder "./" -out "_TEMP.gma"
../../../bin/gmpublish_$suffix update -addon "_TEMP.gma" -id "$WORKSHOP_ID" -icon "icon.jpg"
rm ./_TEMP.gma