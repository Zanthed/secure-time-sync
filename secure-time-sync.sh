#!/bin/bash

# Exits if the script isn't running as root.
if [[ "$(id -u)" -ne 0 ]]; then
    echo "ERROR: This program needs to be run as root."
    exit 1
fi

while test $# -gt 0; do
        case "$1" in
                --use-tor)
                        use_tor="true"
                        break
                        ;;
        esac
done

# Select a random website out of the pool.
select_pool() {
  # Use the onion service if the "--use-tor" flag was set.
  if [ "${use_tor}" = "true" ]; then
    POOL[1]="http://expyuzz4wqqyqhjn.onion"
  else
    POOL[1]="https://www.torproject.org"
  fi

  # Tails website.
  POOL[2]="https://tails.boum.org"

  # Whonix website.
  if [ "${use_tor}" = "true" ]; then
    POOL[3]="http://dds6qkxpwdeubwucdiaord2xgbbeyds25rbsgr73tbfpqpt4a6vjwsyd.onion"
  else
    POOL[3]="https://www.whonix.org"
  fi

  # DuckDuckGo.
  if [ "${use_tor}" = "true" ]; then
    POOL[4]="https://3g2upl4pq6kufc4m.onion"
  else
    POOL[4]="https://duckduckgo.com"
  fi

  # EFF.
  POOL[5]="https://www.eff.org"

  # The last one doesn't get selected. Without the following line, POOL[5] would never be selected.
  POOL[6]=""

  rand=$[$RANDOM % ${#POOL[@]}]
  SELECTED_POOL="${POOL[$rand]}"

  # If nothing was selected, run select_pool again.
  if [ "${SELECTED_POOL}" = "" ]; then
    select_pool
  fi
}

select_pool

if [ "${use_tor}" = "true" ]; then
  # Configure curl to use a socks proxy at localhost on port 9050. This is the default Tor socksport.
  SECURE_CURL="curl -sI --socks5-hostname localhost:9050"
else
  # Protects against https downgrade attacks when not using Tor.
  SECURE_CURL="curl -sI --tlsv1.2 --proto =https"
fi

if ! ${SECURE_CURL} -s ${SELECTED_POOL} &>/dev/null; then
  echo "ERROR: Could not connect to the website."
  exit 1
fi

# Extract the current time from the http header when connecting to one of the websites in the pool.
NEW_TIME=$(${SECURE_CURL} ${SELECTED_POOL} 2>&1 | grep -i "Date" | sed -e 's/Date: //' | sed -e 's/date: //')

# Output the extracted time and selected pool for debugging.
if [ "${DEBUG_TS}" = "1" ]; then
  echo "${SELECTED_POOL}"
  echo "${NEW_TIME}"
fi

# Set the time to the value we just extracted.
date -s "${NEW_TIME}"
