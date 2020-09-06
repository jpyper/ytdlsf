#!/usr/bin/env sh
scriptversion="1.0"
scriptlastedit="20200905 22:52 EST"
scriptauthor="John Pyper"
scriptsite="https://github.com/jpyper/shell-scripts"


#############
### ABOUT ###
#############
# This is a simple script that uses 'youtube-dl' to download almost any
# video from YouTube or other sites supported by the 'youtube-dl' utility.
# It will not allow you to download videos that are private or cost money,
# like video rentals. This script was designed to allow you to backup or
# recover your local lost videos. Do not abuse the system. They're watching.


#################
### CHANGELOG ###
#################
# 20200905 Changed a few minor things to make "shellcheck -a -s sh -o all ./ytdlsf.sh" not return any fix suggestions. POSIX compliant!?
# 20200904 Changed from The MIT License to The Unlicense
# 20200904 Reworked the flow of the script. It's more straight forward and better commented.


####################
### REQUIREMENTS ###
####################
# These are the required external programs for this script to work properly.
# This script was originally written on a Debian stable system, but should work
# as expected on any Debian derivative, including Ubuntu and its derivatives.
# If you are running a different Linux distribution, your mileage may vary.
# -----------------------------------------
# program       -> package that provides it
# -----------------------------------------
# basename      -> coreutils
# find          -> findutils
# mkdir         -> coreutils
# rm            -> coreutils
# test          -> coreutils
# wc            -> coreutils
# youtube-dl    -> youtube-dl


###############
### LICENSE ###
###############
# This script is licensed under The Unlicense.
# Details at the following links:
# https://unlicense.org/
# https://opensource.org/licenses/unlicense
# https://choosealicense.com/licenses/unlicense/
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.


############################
### CONFIGURABLE OPTIONS ###
############################
# s_outdir: full path where to save the file
#s_outdir="/mnt/4tb_media_01/videos/ytdl"
s_outdir="${HOME}/Videos/ytdl"

# s_ytdl_opts: common options for use with 'youtube-dl'. See 'youtube-dl --help' for details.
s_ytdl_options="--ignore-config --ignore-errors --retries 5 --fragment-retries 5 --hls-prefer-native --console-title --no-overwrites --continue --no-check-certificate --format bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best --all-subs --embed-subs --add-metadata --prefer-ffmpeg"

# s_ytdl_outfile: Output Filename Template -- See youtube-dl --help, Filesystem Options: -o command
s_ytdl_outfile="%(title)s [%(height)sp][%(extractor)s][%(id)s].%(ext)s"

# s_ytdl_ua: the user-agent string you want to identify as when connecting to websites.
#s_ytdl_ua="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 Safari/537.36 Edge/84.0.4147.135"
s_ytdl_useragent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.135 Safari/537.36"


######################
### SOME FUNCTIONS ###
######################
# show how to use this script
f_usage() {
	echo "HOW TO USE THIS SCRIPT"
	echo
	echo "Download a file:"
	echo "     $(basename "${0}") https://youtube-dl-compatible-url.com/watch?v=32f3wqf"
	echo
	echo "Tip: If the URL contains an ampersand (\"&\") in it, make sure to quote the URL like so..."
	echo
	echo "     $(basename "${0}") \"https://youtube-dl-compatible-url.com/watch?v=32f3wqf&pl=efvwqerf\""
	echo
	exit
}

# function to display missing dependency information.
f_missing_deps() {
	echo "[E]: Script dependency not found. Please install the package or compile from source."
	echo "       Command: $1"
	echo "   D/U Package: $2"
	echo "      Homepage: $3"
	exit
}


##########################
### SHOW SCRIPT HEADER ###
##########################
echo "+-----------------------------------------------"
echo "| YouTube (and others) Single File Downloader"
echo "| version: ${scriptversion} (${scriptlastedit})"
echo "| by: ${scriptauthor}"
echo "| web: ${scriptsite}"
echo


##############################
### CHECK THE COMMAND LINE ###
##############################
# check command line parameters. no sense in parsing the rest if there's nothing here.
if test ! "${1}"; then
	f_usage
fi


#####################################
### CHECK FOR SCRIPT DEPENDENCIES ###
#####################################
# b_basename: check for 'basename'
b_basename="$(basename --version 2>/dev/null)"
if test "${b_basename}" = ""; then
	f_missing_deps "basename" "coreutils" "https://www.gnu.org/software/coreutils/"
fi

# b_find: check for 'find'
b_find="$(find . --version 2>/dev/null)"
if test "${b_find}" = ""; then
	f_missing_deps "find" "findutils" "https://savannah.gnu.org/projects/findutils/"
fi

# b_mkdir: check for 'mkdir'
b_mkdir="$(mkdir --version 2>/dev/null)"
if test "${b_mkdir}" = ""; then
	f_missing_deps "mkdir" "coreutils" "https://www.gnu.org/software/coreutils/"
fi

# b_rm: check for 'rm'
b_rm="$(rm --version 2>/dev/null)"
if test "${b_rm}" = ""; then
	f_missing_deps "rm" "coreutils" "https://www.gnu.org/software/coreutils/"
fi

# b_test: check for 'test' -- redundant test for 'test'
#b_test="$(test --version 2>/dev/null)"			# this doesn't seem to work, always returns an empty string
#if test "${b_test}" = ""; then
#	f_missing_deps "test" "coreutils" "https://www.gnu.org/software/coreutils/"
#fi

# b_wc: check for 'wc'
b_wc="$(wc --version 2>/dev/null)"
if test "${b_wc}" = ""; then
	f_missing_deps "wc" "coreutils" "https://www.gnu.org/software/coreutils/"
fi

# b_ytdl: check for 'youtube-dl'
b_ytdl="$(youtube-dl --version 2>/dev/null)"
if test "${b_ytdl}" = ""; then
	f_missing_deps "youtube-dl" "youtube-dl" "https://ytdl-org.github.io/youtube-dl/"
fi


##############################
### CHECK OUTPUT DIRECTORY ###
##############################
if test ! -d "${s_outdir}"; then
  mkdir -p "${s_outdir}"
  if test "${?}" -gt "0"; then
  	echo "[E]: There was a problem creating the output directory."
    echo "     Make sure you have write permissions to the directory specified."
    echo
    exit 1
  fi
fi


######################
### GET VIDEO FILE ###
######################
youtube-dl "${s_ytdl_options}" --user-agent "${s_ytdl_useragent}" --output "${s_outdir}/${s_ytdl_outfile}" "${1}"


###################################
### CLEAN UP ANY SUBTITLE FILES ###
###################################
srt_files=$(find "${s_outdir}" -name "*.[Ss][Rt][Tt]" 2>/dev/null | wc -l)
if test "${srt_files}" -gt "0"; then
	echo "[filesys] Removing -${srt_files}- temporary SRT subtitle files."
	rm "${s_outdir}/*.srt"
	echo
fi
