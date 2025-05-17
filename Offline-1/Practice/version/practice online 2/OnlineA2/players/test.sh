#!/usr/bin/env bash
file="Australia/Allrounder/Glenn Maxwell.txt"

# open the file and sequentially read lines into variables
{
  IFS= read -r player_name    # Line 1: “Glenn Maxwell”
  IFS= read -r country        # Line 2: “Australia”
  IFS= read -r _blank         # Line 3: blank
  IFS= read -r role           # Line 4: “Allrounder”
} < "$file"

echo "Country: $country"
echo "Role:    $role"
echo "Player:  $player_name"