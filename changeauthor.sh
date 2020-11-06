#!/bin/sh

# Change the Git history of a repository
#
# Note: Running this script rewrites history for all repository collaborators.
# After completing these steps, any person with forks or clones must fetch
# the rewritten history and rebase any local changes into the rewritten history.
#

VERSION="v2.1.0"

# Set Defaults
SHOW_HELP=0
SHOW_VERSION=0
REPOSITORY_VERIFIED=0 # Set global REPOSITORY_VERIFIED function to false so user must confirm
SHOULD_EXECUTE=0      # Set global SHOULD_EXECUTE function to false so user must confirm
USER_OLD_EMAIL=
USER_NEW_EMAIL=
USER_NEW_NAME=
USER_GIT_DIR=
USER_WORK_TREE=
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
while (("$#")); do

  # Debug: Show flag being evaulated
  # echo "  ${COLOR_CYAN}$1${COLOR_RESET}"

  case "$1" in
  -h | -\? | --help)
    SHOW_HELP=1
    ;;
  -v | -V | --version)
    SHOW_VERSION=1
    ;;
  -f | --force)
    REPOSITORY_VERIFIED=1
    SHOULD_EXECUTE=1
    ;;
  # USER_OLD_EMAIL
  -o | --old-email)
    if [ "$2" ]; then
      USER_OLD_EMAIL="$2"
      shift # Remove argument name from processing
    else
      echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
      exit 1
    fi
    ;;
  -o=*? | --old-email=*?)
    USER_OLD_EMAIL="${1#*=}"
    ;;
  # USER_NEW_EMAIL
  -e | --new-email)
    if [ "$2" ]; then
      USER_NEW_EMAIL="$2"
      shift # Remove argument name from processing
    else
      echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
      exit 1
    fi
    ;;
  -e=*? | --new-email=*?)
    USER_NEW_EMAIL="${1#*=}"
    ;;
  # USER_NEW_NAME
  -n | --new-name)
    if [ "$2" ]; then
      USER_NEW_NAME="$2"
      shift # Remove argument name from processing
    else
      echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
      exit 1
    fi
    ;;
  -n=*? | --new-name=*?)
    USER_NEW_NAME="${1#*=}"
    ;;
  # USER_REMOTE
  -r | --remote)
    if [ "$2" ]; then
      USER_REMOTE="$2"
      shift # Remove argument name from processing
    else
      echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
      exit 1
    fi
    ;;
  -r=*? | --remote=*?)
    USER_REMOTE="${1#*=}"
    ;;
  # USER_GIT_DIR
  -d | --git-dir)
    if [ "$2" ]; then
      USER_GIT_DIR="--git-dir=$2"
      shift # Remove argument name from processing
    else
      echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
      exit 1
    fi
    ;;
  -d=*? | --git-dir=*?)
    USER_GIT_DIR="--git-dir=${1#*=}"
    ;;
  # USER_WORK_TREE
  -w | --work-tree)
    if [ "$2" ]; then
      USER_WORK_TREE="--work-tree=$2"
      shift # Remove argument name from processing
    else
      echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
      exit 1
    fi
    ;;
  -w=*? | --work-tree=*?)
    USER_WORK_TREE="--work-tree=${1#*=}"
    ;;
  # End of all options
  -* | --*=) # unsupported flags
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
showVersion() {
  echo ""
  echo "${COLOR_YELLOW}changeauthor $VERSION${COLOR_RESET}"
  footerInfo
}

footerInfo() {
  echo ""
  echo "For updates and more information:"
  echo "  https://github.com/adamdehaven/change-git-author"
  echo ""
  echo "Created by Adam DeHaven"
  echo "  @adamdehaven or https://www.adamdehaven.com/"
  echo ""
}

# Help text
showHelp() {
  echo ""
  echo "Description:"
  echo "  A bash script to update (change) a git repository's commit author history for a given author email address."
  echo ""
  echo "Usage:"
  echo "  1. Set execute permissions for the script:"
  echo "     ${COLOR_CYAN}chmod +x ./commitauthor.sh${COLOR_RESET}"
  echo "  2. Navigate into the repository with the incorrect commit history:"
  echo "     ${COLOR_CYAN}cd path/to/git/repository${COLOR_RESET}"
  echo "  3. Enter the following to run the script (with or without options):"
  echo "     ${COLOR_CYAN}./commitauthor.sh [OPTIONS]...${COLOR_RESET}"
  echo ""
  echo "      ${COLOR_YELLOW}Note: The script will run in interactive mode if no options are passed.${COLOR_RESET}"
  echo ""
  echo "  Alternatively, you may execute with either of the following:"
  echo "  a) ${COLOR_CYAN}sh ./commitauthor.sh [OPTIONS]...${COLOR_RESET}"
  echo "  b) ${COLOR_CYAN}bash ./commitauthor.sh [OPTIONS]...${COLOR_RESET}"
  echo ""
  echo "Options:"
  echo ""
  echo "  -o, --old-email               The old/incorrect email address of the author you would like to replace in the commit history."
  echo "                                Example: ${COLOR_CYAN}emmett.brown@example.com${COLOR_RESET}"
  echo ""
  echo "  -e, --new-email               The new/corrected email address to replace in commits matching the old email."
  echo "                                Example: ${COLOR_CYAN}marty.mcfly@example.com${COLOR_RESET}"
  echo ""
  echo "  -n, --new-name                The new/corrected name for the new commit author info."
  echo "                                ${COLOR_YELLOW}Be sure to enclose the name in quotes if passing as a flag${COLOR_RESET}"
  echo "                                Example: ${COLOR_CYAN}marty.mcfly@example.com${COLOR_RESET}"
  echo ""
  echo "  -r, --remote                  The name of the repository remote you would like to alter."
  echo "                                Default: ${COLOR_YELLOW}origin${COLOR_RESET}"
  echo "                                Example: ${COLOR_CYAN}github${COLOR_RESET}"
  echo ""
  echo "  -f, --force                   Allows the script to run successfully in a non-interactive shell (assuming "
  echo "                                all required flags are set), bypassing the confirmation prompt."
  echo "                                ${COLOR_YELLOW}WARNING: By passing the --force flag (along with all other required${COLOR_RESET}"
  echo "                                ${COLOR_YELLOW}flags), there is no turning back. Once you start the script,${COLOR_RESET}"
  echo "                                ${COLOR_YELLOW}the process will start and can severely damage your repository.${COLOR_RESET}"
  echo ""
  echo "  -d, --git-dir                 Set the path to the repository (\".git\" directory) if it differs from the current"
  echo "                                directory. It can be an absolute path or relative path to current working directory."
  echo "                                ${COLOR_YELLOW}This option should be used in conjunction with the --work-tree flag.${COLOR_RESET}"
  echo ""
  echo "  -w, --work-tree               Set the path to the working tree. It can be an absolute path or a path relative to "
  echo "                                the current working directory."
  echo ""
  echo "  -v, -V, --version             Show version info."
  echo ""
  echo "  -h, -?, --help                Show this help message."
  footerInfo
}

# If user passed help flag
if [ "$SHOW_HELP" -eq 1 ]; then
  showHelp
  exit
# If user passed version flag
elif [ "$SHOW_VERSION" -eq 1 ]; then
  showVersion
  exit
fi

# Check if --git-dir is inside git repository, if not, exit
INSIDE_GIT_REPO="$(git ${USER_GIT_DIR} ${USER_WORK_TREE} rev-parse --is-inside-work-tree 2>/dev/null)"
if [ ! "$INSIDE_GIT_REPO" ]; then
  echo ""
  echo "${COLOR_RED}ERROR: This is not a git repository.${COLOR_RESET}"
  echo ""
  echo "${COLOR_YELLOW}You must run the script from within a git repository or utilize${COLOR_RESET}"
  echo "${COLOR_YELLOW}the --git-dir and --work-tree flags to set the path to the${COLOR_RESET}"
  echo "${COLOR_YELLOW}repository and working tree. Run with --help for more info.${COLOR_RESET}"
  exit
fi

# USER_OLD_EMAIL
if [ -z "$USER_OLD_EMAIL" ] && [ "$SHOULD_EXECUTE" -eq 0 ]; then
  echo ""
  echo "# ---------------------------------- #"
  echo "# Change Author for Existing Commits #"
  echo "# ---------------------------------- #"
  # Prompt user for email to replace ( USER_OLD_EMAIL )
  echo ""
  echo "Commit Authors:"
  echo "--------------------------------------------"
  echo "$(git ${USER_GIT_DIR} ${USER_WORK_TREE} log --pretty=format:"${COLOR_CYAN}%an - %ae${COLOR_RESET}" | sort -u)"
  echo "--------------------------------------------"
  echo ""
  echo "Enter the email address of the author you "
  echo "would like to replace in the commit history."
  echo "${COLOR_YELLOW}Note: Email matching is case-sensitive.${COLOR_RESET}"
  echo "--------------------------------------------"
  read -e -p "Email to Replace: ${COLOR_CYAN}" USER_OLD_EMAIL
  echo -e "${COLOR_RESET}"
elif [ -z "$USER_OLD_EMAIL" ] && [ "$SHOULD_EXECUTE" -eq 1 ]; then
  echo "${COLOR_RED}ERROR: --old-email is required.${COLOR_RESET}"
  echo "${COLOR_RED}Try again by passing a valid old email address or removing the --force flag."${COLOR_RESET} >&2
  exit 1
fi

if [ -z "$USER_OLD_EMAIL" ]; then
  echo "${COLOR_RED}ERROR: --old-email is required.${COLOR_RESET}"
  echo "${COLOR_RED}Try again by passing a valid old email address or removing the --force flag."${COLOR_RESET} >&2
  exit 1
else
  USER_OLD_EMAIL="${USER_OLD_EMAIL}"
fi

# Check if USER_OLD_EMAIL exists in log
USER_OLD_EMAIL_EXISTS="$(git ${USER_GIT_DIR} ${USER_WORK_TREE} log --pretty=format:"%ae" | grep -w ${USER_OLD_EMAIL})"

# If USER_OLD_EMAIL does NOT exist in log
if [ -z "$USER_OLD_EMAIL_EXISTS" ]; then
  # USER_OLD_EMAIL does not exist in log
  echo ""
  echo "${COLOR_YELLOW}The email '${USER_OLD_EMAIL}' does not exist in the commit history for ${COLOR_RESET}"
  echo "${COLOR_YELLOW}this repository. Please check your spelling and try again.${COLOR_RESET}"
  echo ""
  kill "$SCRIPT_PID"
fi

# USER_NEW_EMAIL
if [ -z "$USER_NEW_EMAIL" ] && [ "$SHOULD_EXECUTE" -eq 0 ]; then
  # Prompt user for correct email ( USER_NEW_EMAIL )
  echo ""
  echo "Enter a new/corrected email for this user."
  echo "------------------------------------------"
  read -e -p "New Email: ${COLOR_CYAN}" USER_NEW_EMAIL
  echo -e "${COLOR_RESET}"
elif [ -z "$USER_NEW_EMAIL" ] && [ "$SHOULD_EXECUTE" -eq 1 ]; then
  echo ""
  echo "${COLOR_RED}ERROR: --new-email is required.${COLOR_RESET}"
  echo "${COLOR_RED}A new email address is required. Please try again.${COLOR_RESET}"
  echo ""
  kill "$SCRIPT_PID"
fi

if [ -z "$USER_NEW_EMAIL" ]; then
  echo "${COLOR_RED}ERROR: --new-email is required.${COLOR_RESET}"
  echo "${COLOR_RED}Try again by passing a valid new email address or removing the --force flag."${COLOR_RESET} >&2
  exit 1
else
  USER_NEW_EMAIL="${USER_NEW_EMAIL}"
fi

if [ "$USER_OLD_EMAIL" == "$USER_NEW_EMAIL" ]; then
  # Remote does not exist
  echo ""
  echo "${COLOR_YELLOW}The old email address, '${USER_OLD_EMAIL}' matches the${COLOR_RESET}"
  echo "${COLOR_YELLOW}new email address you provided, '${USER_NEW_EMAIL}'.${COLOR_RESET}"
  echo ""
  echo "${COLOR_YELLOW}No changes are necessary.${COLOR_RESET}"
  echo ""
  kill "$SCRIPT_PID"
fi

# USER_NEW_NAME
if [ -z "$USER_NEW_NAME" ] && [ "$SHOULD_EXECUTE" -eq 0 ]; then
  # Prompt user for correct name ( USER_NEW_NAME )
  echo ""
  echo "Enter the new/corrected first and last name for this user."
  echo "----------------------------------------------------------"
  read -e -p "New Name: ${COLOR_CYAN}" USER_NEW_NAME
  echo -e "${COLOR_RESET}"
elif [ -z "$USER_NEW_NAME" ] && [ "$SHOULD_EXECUTE" -eq 1 ]; then
  echo ""
  echo "${COLOR_RED}A name is required. Please try again.${COLOR_RESET}"
  echo ""
  kill "$SCRIPT_PID"
fi

if [ -z "$USER_NEW_NAME" ]; then
  echo "${COLOR_RED}ERROR: --new-name is required.${COLOR_RESET}"
  echo "${COLOR_RED}Try again by passing a valid new name or removing the --force flag."${COLOR_RESET} >&2
  exit 1
else
  USER_NEW_NAME="${USER_NEW_NAME}"
fi

# USER_REMOTE
if [ -z "$USER_REMOTE" ] && [ "$SHOULD_EXECUTE" -eq 0 ]; then
  # Prompt user for remote (Default: 'origin' )
  echo ""
  echo "Enter the remote you would like to alter. ${COLOR_YELLOW}(Default: origin)${COLOR_RESET}"
  echo "--------------------------------------------------------"
  read -e -p "Remote Name: ${COLOR_CYAN}" -i "${DEFAULT_REMOTE}" USER_REMOTE
  echo -e "${COLOR_RESET}"
elif [ -z "$USER_REMOTE" ] && [ "$SHOULD_EXECUTE" -eq 1 ]; then
  # Running non-interactive, so set to default
  USER_REMOTE="$DEFAULT_REMOTE"
fi

if [ -z "$USER_REMOTE" ]; then
  USER_REMOTE="${DEFAULT_REMOTE}"
else
  USER_REMOTE="${USER_REMOTE}"
fi

# Have user verify repository
if [ "$REPOSITORY_VERIFIED" -eq 0 ]; then
  while true; do
    echo ""
    echo "Please verify that the remote repository shown below is correct:"
    echo "Remote URL: ${COLOR_YELLOW}$(git ${USER_GIT_DIR} ${USER_WORK_TREE} config --get remote.${USER_REMOTE}.url)${COLOR_RESET}"
    echo "--------------------------------------------------------"
    read -e -p "${COLOR_RED}Is this the correct repository? [y/n]: ${COLOR_CYAN}" USER_CONFIRM
    echo -e "${COLOR_RESET}"
    case $USER_CONFIRM in
    [Yy]*)
      REPOSITORY_VERIFIED=1
      break
      ;;
    [Nn]*)
      REPOSITORY_VERIFIED=0
      break
      ;;
    *)
      echo ""
      echo "   ${COLOR_YELLOW}You must enter 'Y' to verify the repository, or 'N' to cancel${COLOR_RESET}"
      echo ""
      ;;
    esac
  done
fi

# Check if remote exists in repository
VALID_REMOTES="$(git ${USER_GIT_DIR} ${USER_WORK_TREE} remote | grep -w ${USER_REMOTE})"
if [ -z "$VALID_REMOTES" ]; then
  # Remote does not exist
  echo ""
  echo "${COLOR_YELLOW}The remote '${USER_REMOTE}' does not exist for this repository.${COLOR_RESET}"
  echo "${COLOR_YELLOW}Please check your spelling and try again.${COLOR_RESET}"
  echo ""
  kill "$SCRIPT_PID"
fi

# Have the user confirm before executing (if they didn't already cancel)
if [ "$SHOULD_EXECUTE" -eq 0 ] && [ "$REPOSITORY_VERIFIED" -eq 1 ]; then
  while true; do
    echo ""
    echo "Are you sure you want to rewrite the entire"
    echo "history of your Git repository?"
    echo "-------------------------------------------"
    echo "Old email:  ${COLOR_CYAN}${USER_OLD_EMAIL}${COLOR_RESET}"
    echo "New email:  ${COLOR_CYAN}${USER_NEW_EMAIL}${COLOR_RESET}"
    echo "New name:   ${COLOR_CYAN}${USER_NEW_NAME}${COLOR_RESET}"
    echo "Remote:     ${COLOR_CYAN}${USER_REMOTE}${COLOR_RESET}"
    echo "Remote URL: ${COLOR_CYAN}$(git ${USER_GIT_DIR} ${USER_WORK_TREE} config --get remote.${USER_REMOTE}.url)${COLOR_RESET}"
    echo ""
    echo "${COLOR_YELLOW}Note: Running this script rewrites history for all${COLOR_RESET}"
    echo "${COLOR_YELLOW}repository collaborators. Any person with forks ${COLOR_RESET}"
    echo "${COLOR_YELLOW}or clones must fetch the rewritten history and${COLOR_RESET}"
    echo "${COLOR_YELLOW}rebase any local changes into the rewritten history.${COLOR_RESET}"
    echo ""
    read -e -p "${COLOR_RED}Continue? [y/n]: ${COLOR_CYAN}" USER_CONFIRM
    echo -e "${COLOR_RESET}"
    case $USER_CONFIRM in
    [Yy]*)
      SHOULD_EXECUTE=1
      break
      ;;
    [Nn]*)
      SHOULD_EXECUTE=0
      break
      ;;
    *)
      echo ""
      echo "   ${COLOR_YELLOW}You must enter 'Y' to confirm, or 'N' to cancel${COLOR_RESET}"
      echo ""
      ;;
    esac
  done
fi

echo ""

# If SHOULD_EXECUTE is true, and REPOSITORY_VERIFIED is true, rewrite repo history, otherwise, kill
if [ "$SHOULD_EXECUTE" -eq 1 ] && [ "$REPOSITORY_VERIFIED" -eq 1 ]; then
  # Alter commits and rewrite history
  git ${USER_GIT_DIR:+-$USER_GIT_DIR} ${USER_WORK_TREE:+-$USER_WORK_TREE} filter-branch -f --env-filter '
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
  echo ""
  echo "${COLOR_YELLOW}You have 5 seconds to cancel (Ctrl + C)${COLOR_RESET}"
  echo ""
  # Sleep for a sec to let user cancel
  sleep 5

  # Update Remote
  git ${USER_GIT_DIR:+-$USER_GIT_DIR} ${USER_WORK_TREE:+-$USER_WORK_TREE} push --force --tags "$USER_REMOTE" 'refs/heads/*'

  echo ""
  echo "${COLOR_GREEN}Successfully Updated Remote Author Info${COLOR_RESET}"
  echo ""
  echo "${COLOR_GREEN}The author info for commits linked to ${COLOR_GREEN}'${USER_OLD_EMAIL}' have ${COLOR_RESET}"
  echo "${COLOR_GREEN}been updated to '${USER_NEW_NAME} <${USER_NEW_EMAIL}>' and${COLOR_RESET}"
  echo "${COLOR_GREEN}the changes have been pushed to remote '${USER_REMOTE}'. ${COLOR_RESET}"
else
  # User Cancelled
  echo "${COLOR_YELLOW}Changes Cancelled.${COLOR_RESET}"
  echo "${COLOR_YELLOW}No changes were pushed to remote '${USER_REMOTE}'.${COLOR_RESET}"
fi

# Reset global vars
REPOSITORY_VERIFIED=0
SHOULD_EXECUTE=0
# Reset git environment variables
USER_GIT_DIR=
USER_WORK_TREE=
