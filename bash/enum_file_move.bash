#!/bin/bash

for file in something_number*.pdf; do
  if [[ "$file" =~ prilog_([0-9]{2})_ ]]; then
    old_number="${BASH_REMATCH[1]}"

    # Skip if the old number is less than 06
    if (( 10#"$old_number" < 6 )); then
      echo "Skipping '$file' as its number ($old_number) is less than 06."
      continue
    fi

    new_number=$((10#"$old_number" + 1))
    new_number_padded=$(printf "%02d" "$new_number")
    new_file="something_number${new_number_padded}.pdf"
    echo "Moving '$file' to '$new_file'"
    # mv "$file" "$new_file"
  fi
done

