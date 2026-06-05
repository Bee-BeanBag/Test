#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (blamsma26): " username
    username=${username:-blamsma26}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_235000_0600.dat.gz"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_235000_0600.dat.gz -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_235000_0600.dat.gz | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_235000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_234000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_233000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_232000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_231000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_230000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_225000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_224000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_223000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_222000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_221000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_220000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_215000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_214000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_213000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_212000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_211000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_210000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_205000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_204000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_203000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_202000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_201000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_200000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_195000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_194000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_193000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_192000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_191000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_190000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_185000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_184000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_183000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_182000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_181000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_180000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_175000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_174000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_173000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_172000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_171000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_170000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_165000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_164000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_163000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_162000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_161000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_160000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_155000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_154000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_153000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_152000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_151000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_150000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_145000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_144000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_143000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_142000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_141000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_140000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_135000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_134000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_133000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_132000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_131000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_130000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_125000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_124000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_123000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_122000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_121000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_120000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_115000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_114000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_113000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_112000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_111000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_110000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_105000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_104000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_103000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_102000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_101000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_100000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_095000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_094000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_093000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_092000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_091000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_090000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_085000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_084000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_083000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_082000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_081000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_080000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_075000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_074000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_073000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_072000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_071000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_070000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_065000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_064000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_063000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_062000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_061000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_060000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_055000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_054000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_053000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_052000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_051000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_050000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_045000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_044000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_043000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_042000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_041000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_040000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_035000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_034000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_033000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_032000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_031000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_030000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_025000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_024000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_023000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_022000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_021000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_020000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_015000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_014000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_013000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_012000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_011000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_010000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_005000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_004000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_003000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_002000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_001000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200601_000000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200531_235000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200531_234000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200531_233000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200531_232000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200531_231000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_200531_230000_0600.dat.gz
EDSCEOF