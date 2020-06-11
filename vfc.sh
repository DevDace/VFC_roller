#!/bin/bash

########
# INPUT VARS
########

INPUT_SHOTS=2d6
BS=3
STR=8
AP=2
DMG=1d3
TOU=4
SAV=2
WOU=3
MODELS=3

########
# FUNC
########
##
# Return a random number between 1 and $1
##
# $1: size of the dice
##
roll_dice() {
  shuf -i 1-"$1" -n 1
  exit 0
}

##
# Compute number of SHOTS
##
#
##
compute_shots() {
  if [[ $INPUT_SHOTS =~ [dD] ]]; then
    # number of rolls
    n=$(sed -r 's/[dD][0-9]+//' <<< $INPUT_SHOTS)
    # die size
    dice=$(sed -r 's/[0-9]+[dD]//' <<< $INPUT_SHOTS)

    # let's get rolling
    SHOTS=0
    for ((i=0; i<n; i++)); do
      rolled=$(roll_dice "$dice")
      SHOTS=$((SHOTS + rolled))
    done
  else
    SHOTS=$INPUT_SHOTS
  fi
  echo "$SHOTS shots"
}

##
# Compute number of HITS
##
#
##
compute_hits() {
  HITS=0
  for ((i=0; i<SHOTS; i++)); do
    rolled=$(roll_dice 6)

    # roll of 1 always fail, so BS2 is the best case used
    [[ $BS -lt 2 ]] && BS=2

    if [[ $rolled -ge $BS ]]; then
      HITS=$((HITS + 1))
    fi
  done
  echo "$HITS hits"
}

##
# Compute number of WOUNDS
##
#
##
compute_wounds() {
  WOUNDS=0
  for ((i=0; i<HITS; i++)); do
    rolled=$(roll_dice 6)

    diff_w=$((STR-TOU))

    # compute roll threshold, i.e. target number to wound
    threshold_w=$((
      diff_w == 0     ? 4 :
      diff_w >= TOU   ? 2 :
      diff_w > 0      ? 3 :
      diff_w <= -STR  ? 6 :
      diff_w < 0      ? 5 :
      255))
    [[ $threshold_w -eq 255 ]] && echo "This is heresy" && exit 250

    if [[ $rolled -ge $threshold_w ]]; then
      WOUNDS=$((WOUNDS + 1))
    fi
  done
  echo "$WOUNDS wounds"
}


##
# Compute number of failed SAVES
##
#
##
compute_saves() {
  F_SAVES=0
  for ((i=0; i<WOUNDS; i++)); do
    rolled=$(roll_dice 6)

    # AP is saved as a negative number, so substracting it to the save value gives the real value
    threshold_s=$((SAV-AP))

    # roll of 1 always a fail: a better than 2+ save is treated as a 2+
    [[ $threshold_s -lt 2 ]] && threshold_s=2

    if [[ $rolled -lt $threshold_s ]]; then
      F_SAVES=$((F_SAVES + 1))
    fi
  done
  echo "$F_SAVES failed saves"
}

##
# Compute number of DAMAGES
##
#
##
compute_dmg() {
  TOTAL_DMG=0
  CURRENT_MODEL_HP=$WOU
  KILLED=0
  # TODO improve this if for the following cases: single big unit, large unit of 1W units, small unit of multi-wounds models
  if [[ $MODELS -gt 1 ]] && [[ $WOU -eq 1 ]]; then
    KILLED=$((KILLED + 1))

    echo "$KILLED models killed"
    return 0
  fi


  # Compute dmg rolls parameters
  if [[ $DMG =~ [dD] ]]; then
    # number of rolls
    n=$(sed -r 's/[dD][0-9]+//' <<< $DMG)
    # die size
    dice=$(sed -r 's/[0-9]+[dD]//' <<< $DMG)

    roll_dmg=1
  fi

  for ((i=0; i<F_SAVES; i++)); do
    # Compute dmg done
    if [[ -n $roll_dmg ]]; then
      dmg_dealt=0
      for ((j=0; j<n; j++)); do
        rolled=$(roll_dice "$dice")
        dmg_dealt=$((dmg_dealt + rolled))
      done
    else
      dmg_dealt=$DMG
    fi
    TOTAL_DMG=$((TOTAL_DMG + dmg_dealt))


    # Check if we killed a model
    CURRENT_MODEL_HP=$((CURRENT_MODEL_HP - dmg_dealt))
    if [[ $CURRENT_MODEL_HP -le 0 ]]; then
      CURRENT_MODEL_HP=$WOU
      KILLED=$((KILLED + 1))
    fi
  done

  echo "$TOTAL_DMG total dmg done"
  echo "$KILLED models killed"
  if [[ $KILLED -ne $MODELS ]]; then
    # TODO improve the if for the case we did 0 damage to a unit
    echo "${CURRENT_MODEL_HP}/${WOU} HP left on a model"
  fi
}

########
# MAIN
########

compute_shots

compute_hits

compute_wounds

compute_saves

compute_dmg

exit 0
