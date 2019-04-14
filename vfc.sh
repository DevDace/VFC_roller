#!/bin/bash

########
# VARS
########

INPUT_SHOTS=3d6

########
# FUNC
########
##
# Return a random number between 1 and $1
##
# $1: size of the dice
##
roll_dice() {
  echo $(shuf -i 1-$1 -n 1)
  exit 0
}

########
# SHOTS
########
if [[ $INPUT_SHOTS =~ [dD] ]]; then
  n=$(sed -r 's/[dD][0-9]+//' <<< $INPUT_SHOTS)
  dice=$(sed -r 's/[0-9]+[dD]//' <<< $INPUT_SHOTS)

  SHOTS=0
  for ((i=0; i<$n; i++)); do
    rolled=$(roll_dice $dice)
    SHOTS=$((SHOTS + rolled))
  done
else
  SHOTS=$INPUT_SHOTS
fi
echo "$SHOTS shots"
