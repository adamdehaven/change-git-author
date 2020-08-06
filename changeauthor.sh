#!/bin/sh

# Change the Git history of a repository
#
# Note: Running this script rewrites history for all repository collaborators.
# After completing these steps, any person with forks or clones must fetch
# the rewritten history and rebase any local changes into the rewritten history.
#

VERSION="v2.0.0"

# Set Defaults
SHOW_HELP=0
SHOW_VERSION=0
SHOULD_EXECUTE=0 # Set global SHOULD_EXECUTE function to false so user must confirm
USER_OLD_EMAIL=
USER_NEW_EMAIL=
USER_NEW_NAME=
DEFAULT_REMOTE="origin"
USER_REMOTE=

# Set Colors
COLOR_RED=$'\e[31m'
COLOR_CYAN=$'\e[36m'
COLOR_YELLOW=$'\e[93m'
COLOR_GREEN=$'\e[32m'
COLOR_RESET=$'\e[0m'

# Get PID of process to kill later if needed
SCRIPT_PID=$$

PARAMS=""

# Loop through arguments and process them
while (( "$#" )); do

    # Debug: Show flag being evaulated
    # echo "  ${COLOR_CYAN}$1${COLOR_RESET}"

    case "$1" in
        -h|-\?|--help)
            SHOW_HELP=1
            ;;
        -v|-V|--version)
            SHOW_VERSION=1
            ;;
        -f|--force)
            SHOULD_EXECUTE=1
            ;;
        # USER_OLD_EMAIL
        -o|--old-email)
            if [ "$2" ]; then
                USER_OLD_EMAIL="$2"
                shift # Remove argument name from processing
            else
                echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
                exit 1
            fi
            ;;
        -o=*?|--old-email=*?)
            USER_OLD_EMAIL="${1#*=}"
            shift # Remove domain from processing
            ;;
        # USER_NEW_EMAIL
        -e|--new-email)
            if [ "$2" ]; then
                USER_NEW_EMAIL="$2"
                shift # Remove argument name from processing
            else
                echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
                exit 1
            fi
            ;;
        -e=*?|--new-email=*?)
            USER_NEW_EMAIL="${1#*=}"
            shift # Remove domain from processing
            ;;
        # USER_NEW_NAME
        -n|--new-name)
            if [ "$2" ]; then
                USER_NEW_NAME="$2"
                shift # Remove argument name from processing
            else
                echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
                exit 1
            fi
            ;;
        -n=*?|--new-name=*?)
            USER_NEW_NAME="${1#*=}"
            shift # Remove domain from processing
            ;;
        # End of all options
        -*|--*=) # unsupported flags
            echo "${COLOR_RED}ERROR: Flag $1 is not a supported option."${COLOR_RESET} >&2
            exit 1
            ;;
        # preserve positional arguments
        *)
            PARAMS="${PARAMS} $1"
            shift
            ;;
    esac
    shift
done

# Set positional arguments in their proper place
eval set -- "$PARAMS"

# Version
showVersion()
{
    echo ""
    echo "${COLOR_YELLOW}changeauthor $VERSION${COLOR_RESET}"
    footerInfo
}

footerInfo()
{
    echo ""
    echo "For updates and more information:"
    echo "  https://github.com/adamdehaven/change-git-author"
    echo ""
    echo "Created by Adam DeHaven"
    echo "  @adamdehaven or https://www.adamdehaven.com/"
    echo ""
}

# Help text
# showHelp()
# {
#  echo ""
#  echo "Description:"
#  echo "  A bash script to spider a site, follow links, and fetch urls (with built-in filtering) into a generated text file."
#  echo ""
#  if [ "$WGET_INSTALLED" -eq 0 ]; then
#      echo "Requirements:"
#      echo "  ${COLOR_YELLOW}You'll need wget installed in order to continue.${COLOR_RESET}"
#      echo "  For more information, run with the --wget flag, or check out https://github.com/adamdehaven/fetchurls#usage"
#      echo ""
#  fi
#  echo "Usage:"
#  echo "  1. Set execute permissions for the script:"
#  echo "     ${COLOR_CYAN}chmod +x ./fetchurls.sh${COLOR_RESET}"
#  echo "  2. Enter the following to run the script:"
#  echo "      ${COLOR_CYAN}./fetchurls.sh [OPTIONS]...${COLOR_RESET}"
#  echo ""
#  echo "      ${COLOR_YELLOW}Note: The script will run in interactive mode if no options are passed.${COLOR_RESET}"
#  echo ""
#  echo "  Alternatively, you may execute with either of the following:"
#  echo "  a) ${COLOR_CYAN}sh ./fetchurls.sh [OPTIONS]...${COLOR_RESET}"
#  echo "  b) ${COLOR_CYAN}bash ./fetchurls.sh [OPTIONS]...${COLOR_RESET}"
#  echo ""
#  echo "Options:"
#  echo ""
#  echo "  -d, --domain                  The fully qualified domain URL (with protocol) you would like to crawl."
#  echo "                                If you do not pass the --domain flag, the script will run in interactive mode."
#  echo "                                Example: ${COLOR_CYAN}https://example.com${COLOR_RESET}"
#  echo ""
#  echo "  -l, --location                The location (directory) where you would like to save the generated results."
#  echo "                                Default: ${COLOR_YELLOW}~/Desktop${COLOR_RESET}"
#  echo "                                Example: ${COLOR_CYAN}/c/Users/username/Desktop${COLOR_RESET}"
#  echo ""
#  echo "  -f, --filename                The name of the generated file, without spaces or file extension."
#  echo "                                Default: ${COLOR_YELLOW}domain-topleveldomain${COLOR_RESET}"
#  echo "                                Example: ${COLOR_CYAN}example-com${COLOR_RESET}"
#  echo ""
#  echo "  -e, --exclude                 Pipe-delimited list of file extensions to exclude from results."
#  echo "                                The list of file extensions must be passed inside quotes."
#  echo "                                To prevent excluding files matching the default list, simply pass an empty string: \"\""
#  echo "                                Default: ${COLOR_YELLOW}\"$DEFAULT_EXCLUDED_EXTENTIONS\"${COLOR_RESET}"
#  echo "                                Example: ${COLOR_CYAN}\"css|js|map\"${COLOR_RESET}"
#  echo ""
#  echo "  -n, --non-interactive         Allows the script to run successfully in a non-interactive shell."
#  echo "                                Uses the default --location and --filename settings unless the corresponding flags are set."
#  echo ""
#  echo "  -w, --wget                    Show wget install instructions."
#  echo "                                The installation process may vary depending on your computer's configuration."
#  echo ""
#  echo "  -v, -V, --version             Show version info."
#  echo ""
#  echo "  -t, --troubleshooting         Output arguments passed as flags for troubleshooting."
#  echo ""
#  echo "  -h, -?, --help                Show this help message."
#  footerInfo
# }

# If user passed help flag
if [ "$SHOW_HELP" -eq 1 ]; then
    showHelp
    exit
# If user passed version flag
elif [ "$SHOW_VERSION" -eq 1 ]; then
    showVersion
    exit
fi

# USER_OLD_EMAIL
if [ -z "$USER_OLD_EMAIL" ] && [ "$SHOULD_EXECUTE" -eq 0 ]; then
    echo ""
    echo "Change Author for Existing Commits"
    echo "----------------------------------"
    # Prompt user for email to replace ( USER_OLD_EMAIL )
    echo ""
    echo "1. Enter the email address of the author you "
    echo "   would like to replace in the commit history."
    echo ""
    read -e -p "   Email to Replace: ${COLOR_CYAN}" USER_OLD_EMAIL
    echo -e "${COLOR_RESET}"
elif [ -z "$USER_OLD_EMAIL" ] && [ "$SHOULD_EXECUTE" -eq 1 ]; then
    echo "${COLOR_RED}ERROR: --old-email is required.${COLOR_RESET}"
    echo "${COLOR_RED}Try again by passing a valid old email address or removing the --force flag."${COLOR_RESET} >&2
    exit 1
fi

eval USER_OLD_EMAIL="$USER_OLD_EMAIL"

# Check if USER_OLD_EMAIL exists in log
USER_OLD_EMAIL_EXISTS="$(git log --pretty=format:"%ae" | grep -w ${USER_OLD_EMAIL})"

# If USER_OLD_EMAIL does NOT exist in log
if [ -z "$USER_OLD_EMAIL_EXISTS" ]; then
    # USER_OLD_EMAIL does not exist in log
    echo "${COLOR_RED}The email '${USER_OLD_EMAIL}' does not${COLOR_RESET}"
    echo "${COLOR_RED}exist in the log. Please check your spelling${COLOR_RESET}"
    echo "${COLOR_RED}and try again.${COLOR_RESET}"
    echo ""
    kill "$SCRIPT_PID"
fi

# USER_NEW_EMAIL
if [ -z "$USER_NEW_EMAIL" ] && [ "$SHOULD_EXECUTE" -eq 0 ]; then
    # Prompt user for correct email ( USER_NEW_EMAIL )
    echo "2. Enter a new/corrected email for this user."
    echo ""
    read -e -p "   New Email: ${COLOR_CYAN}" USER_NEW_EMAIL
    echo -e "${COLOR_RESET}"
elif [ -z "$USER_NEW_EMAIL" ] && [ "$SHOULD_EXECUTE" -eq 1 ]; then
    echo "${COLOR_RED}An email address is required. Please try again.${COLOR_RESET}"
    echo ""
    kill "$SCRIPT_PID"
fi

eval USER_NEW_EMAIL="$USER_NEW_EMAIL"

# USER_NEW_NAME
if [ -z "$USER_NEW_NAME" ] && [ "$SHOULD_EXECUTE" -eq 0 ]; then
    # Prompt user for correct name ( USER_NEW_NAME )
    echo "3. Enter the new/corrected name for this user."
    echo "   ${COLOR_YELLOW}(Be sure to enclose name in quotes)${COLOR_RESET}"
    echo ""
    read -e -p "   New Name: ${COLOR_CYAN}" USER_NEW_NAME
    echo -e "${COLOR_RESET}"
elif [ -z "$USER_NEW_NAME" ] && [ "$SHOULD_EXECUTE" -eq 1 ]; then
    echo "${COLOR_RED}A name is required. Please try again.${COLOR_RESET}"
    echo ""
    kill "$SCRIPT_PID"
fi

eval USER_NEW_NAME="$USER_NEW_NAME"

# USER_REMOTE
if [ -z "$USER_REMOTE" ] && [ "$SHOULD_EXECUTE" -eq 0 ]; then
    # Prompt user for remote (Default: 'origin' )
    echo "4. Enter the remote you would like to alter."
    echo "   ${COLOR_YELLOW}(Default: origin)${COLOR_RESET}"
    echo ""
    read -e -p "   Remote Name: ${COLOR_CYAN}" -i "${DEFAULT_REMOTE}" USER_REMOTE
    echo -e "${COLOR_RESET}"
elif [ -z "$USER_REMOTE" ] && [ "$SHOULD_EXECUTE" -eq 1 ]; then
    # Running non-interactive, so set to default
    USER_REMOTE="$DEFAULT_REMOTE"
fi

eval USER_REMOTE="${USER_REMOTE}"

# Check if remote exists in repository
VALID_REMOTES="$(git remote | grep -w ${USER_REMOTE})"
if [ -z "$VALID_REMOTES" ]; then
    # Remote does not exist
    echo "${COLOR_RED}The remote '${USER_REMOTE}' does not exist for${COLOR_RESET}"
    echo "${COLOR_RED}this repository. Please check your${COLOR_RESET}"
    echo "${COLOR_RED}spelling and try again.${COLOR_RESET}"
    echo ""
    kill "$SCRIPT_PID"
fi

# Have the user confirm before executing
if [ "$SHOULD_EXECUTE" -eq 0 ]; then
    while true; do
        echo "5. ${COLOR_RED}Are you sure you want to rewrite the entire ${COLOR_RESET}"
        echo "   ${COLOR_RED}history of your Git repository?${COLOR_RESET}"
        echo "   "
        echo "   ${COLOR_YELLOW}Note: Running this script rewrites history for all${COLOR_RESET}"
        echo "   ${COLOR_YELLOW}repository collaborators. Any person with forks ${COLOR_RESET}"
        echo "   ${COLOR_YELLOW}or clones must fetch the rewritten history and${COLOR_RESET}"
        echo "   ${COLOR_YELLOW}rebase any local changes into the rewritten history.${COLOR_RESET}"
        echo ""
        read -e -p "   [y/n]: ${COLOR_CYAN}" USER_CONFIRM
        echo -e "${COLOR_RESET}"
        case $USER_CONFIRM in
            [Yy]* ) SHOULD_EXECUTE=1; break;;
            [Nn]* ) SHOULD_EXECUTE=0; break;;
            * ) echo ""; echo "   ${COLOR_YELLOW}You must enter 'Y' to confirm, or 'N' to cancel${COLOR_RESET}"; echo "";;
        esac
    done
fi

# If SHOULD_EXECUTE is true, rewrite repo history, otherwise, kill
if [ "$SHOULD_EXECUTE" -eq 1 ]; then
    # Alter commits and rewrite history
    git filter-branch --env-filter '
    if [ "$GIT_COMMITTER_EMAIL" = "'"$USER_OLD_EMAIL"'" ]
    then
        export GIT_COMMITTER_NAME="'"$USER_NEW_NAME"'"
        export GIT_COMMITTER_EMAIL="'"$USER_NEW_EMAIL"'"
    fi
    if [ "$GIT_AUTHOR_EMAIL" = "'"$USER_OLD_EMAIL"'" ]
    then
        export GIT_AUTHOR_NAME="'"$USER_NEW_NAME"'"
        export GIT_AUTHOR_EMAIL="'"$USER_NEW_EMAIL"'"
    fi
    ' --tag-name-filter cat -- --branches --tags

    # Show Success Message
    echo ""
    echo "${COLOR_GREEN}Successfully Updated Local Author Info${COLOR_RESET}"
    echo ""
    echo "Preparing to push to remote '${USER_REMOTE}'..."
    echo "${COLOR_YELLOW}(You have 5 seconds to cancel [Ctrl + C])${COLOR_RESET}"
    echo ""
    # Sleep for a sec to let user cancel
    sleep 5

    # Update Remote
    git push --force --tags "$USER_REMOTE" 'refs/heads/*'

    echo ""
    echo "${COLOR_GREEN}Successfully Updated Remote Author Info${COLOR_RESET}"
    echo ""
    echo "${COLOR_GREEN}The author info for commits linked to${COLOR_RESET}"
    echo "${COLOR_GREEN}'${USER_OLD_EMAIL}' have been updated to${COLOR_RESET}"
    echo "${COLOR_GREEN}'${USER_NEW_NAME} <${USER_NEW_EMAIL}>' and the changes${COLOR_RESET}"
    echo "${COLOR_GREEN}have been pushed to remote '${USER_REMOTE}'. ${COLOR_RESET}"
else
    # User Canceled
    echo ""
    echo "${COLOR_GREEN}Successfully Canceled.${COLOR_RESET}"
    echo "${COLOR_GREEN}No changes were pushed to remote '${USER_REMOTE}'.${COLOR_RESET}"
fi
