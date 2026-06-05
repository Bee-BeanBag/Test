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
    echo "https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221108_005000_0600.dat.gz"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221108_005000_0600.dat.gz -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221108_005000_0600.dat.gz | tail -1)
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
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221108_005000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221108_004000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221108_003000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221108_002000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221108_001000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221108_000000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_235000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_234000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_233000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_232000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_231000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_230000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_225000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_224000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_223000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_222000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_221000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_220000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_215000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_214000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_213000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_212000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_211000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_210000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_205000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_204000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_203000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_202000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_201000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_200000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_195000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_194000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_193000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_192000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_191000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_190000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_185000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_184000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_183000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_182000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_181000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_180000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_175000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_174000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_173000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_172000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_171000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_170000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_165000_0600.dat.gz
https://data.ghrc.earthdata.nasa.gov/ghrcw-protected/nalma__1/NALMA_221107_164000_0600.dat.gz
EDSCEOF