#!/bin/bash

#
# Change the Git history of a repository
#
# Note: Running this script rewrites history for all repository collaborators.
# After completing these steps, any person with forks or clones must fetch
# the rewritten history and rebase any local changes into the rewritten history.
#

VERSION="v2.4.1"

# Set Defaults
SHOW_HELP=0
SHOW_VERSION=0
REPOSITORY_VERIFIED=0 # Set global REPOSITORY_VERIFIED function to false so user must confirm
SHOULD_EXECUTE=0      # Set global SHOULD_EXECUTE function to false so user must confirm
REMOTE_REPOSITORY=
USER_OLD_EMAIL=
USER_NEW_EMAIL=
USER_NEW_NAME=
USER_GIT_DIR=
USER_WORK_TREE=
UPDATE_REMOTE=
DEFAULT_REMOTE="origin"
USER_REMOTE=

# Set Colors
COLOR_RED=$'\e[31m'
COLOR_CYAN=$'\e[36m'
COLOR_YELLOW=$'\e[93m'
COLOR_GREEN=$'\e[32m'
COLOR_RESET=$'\e[0m'

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
      USER_OLD_EMAIL=$(echo "$2" | awk "{print tolower(\$0)}")
      shift # Remove argument name from processing
    else
      echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
      exit 1
    fi
    ;;
  -o=*? | --old-email=*?)
    USER_OLD_EMAIL=$(echo "${1#*=}" | awk "{print tolower(\$0)}")
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
      # Automatically set UPDATE_REMOTE to true
      UPDATE_REMOTE=1
      shift # Remove argument name from processing
    else
      echo "${COLOR_RED}ERROR: Value for $1 is required."${COLOR_RESET} >&2
      exit 1
    fi
    ;;
  -r=*? | --remote=*?)
    USER_REMOTE="${1#*=}"
    # Automatically set UPDATE_REMOTE to true
    UPDATE_REMOTE=1
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
  echo "     ${COLOR_CYAN}chmod +x ./changeauthor.sh${COLOR_RESET}"
  echo "  2. Navigate into the repository with the incorrect commit history:"
  echo "     ${COLOR_CYAN}cd path/to/git/repository${COLOR_RESET}"
  echo ""
  echo "     Alternatively, you can run from anywhere by passing the ${COLOR_CYAN}--git-dir${COLOR_RESET} and ${COLOR_CYAN}--work-tree${COLOR_RESET} flags."
  echo ""
  echo "  3. Enter the following to run the script (with or without options):"
  echo "     ${COLOR_CYAN}./changeauthor.sh [OPTIONS]...${COLOR_RESET}"
  echo ""
  echo "     Alternatively, you may execute with either of the following:"
  echo "     a) ${COLOR_CYAN}sh ./changeauthor.sh [OPTIONS]...${COLOR_RESET}"
  echo "     b) ${COLOR_CYAN}bash ./changeauthor.sh [OPTIONS]...${COLOR_RESET}"
  echo ""
  echo "     ${COLOR_YELLOW}Note: The script will run in interactive mode if no options are passed.${COLOR_RESET}"
  echo ""
  echo "Options:"
  echo ""
  echo "  -o, --old-email               The old/incorrect email address of the author you would like to "
  echo "                                replace in the commit history."
  echo "                                Example: ${COLOR_CYAN}emmett.brown@example.com${COLOR_RESET}"
  echo ""
  echo "  -e, --new-email               The new/corrected email address to replace in commits matching"
  echo "                                the old email."
  echo "                                Example: ${COLOR_CYAN}marty.mcfly@example.com${COLOR_RESET}"
  echo ""
  echo "  -n, --new-name                The new/corrected name for the new commit author info."
  echo "                                ${COLOR_YELLOW}Be sure to enclose the name in quotes if passing as a flag${COLOR_RESET}"
  echo "                                Example: ${COLOR_CYAN}Marty McFly${COLOR_RESET}"
  echo ""
  echo "  -r, --remote                  The name of the repository remote you would like to alter."
  echo "                                Default: ${COLOR_YELLOW}origin${COLOR_RESET}"
  echo "                                Example: ${COLOR_CYAN}github${COLOR_RESET}"
  echo ""
  echo "  -f, --force                   Allows the script to run successfully in a non-interactive"
  echo "                                shell (assuming all required flags are set), bypassing "
  echo "                                the confirmation prompt."
  echo "                                ${COLOR_YELLOW}WARNING: By passing the --force flag (along with all other${COLOR_RESET}"
  echo "                                ${COLOR_YELLOW}required flags), there is no turning back. Once you start${COLOR_RESET}"
  echo "                                ${COLOR_YELLOW}the script, the process will start and can severely${COLOR_RESET}"
  echo "                                ${COLOR_YELLOW}damage your repository if used incorrectly.${COLOR_RESET}"
  echo ""
  echo "  -d, --git-dir                 Set the path to the repository (\".git\" directory) if it"
  echo "                                differs from the current directory. It can be an absolute path or"
  echo "                                relative path to current working directory."
  echo "                                ${COLOR_YELLOW}This option should be used in conjunction with${COLOR_RESET}"
  echo "                                ${COLOR_YELLOW}the --work-tree flag.${COLOR_RESET}"
  echo ""
  echo "  -w, --work-tree               Set the path to the working tree. It can be an absolute"
  echo "                                path or a path relative to the current working directory."
  echo ""
  echo "  -v, -V, --version             Show version info."
  echo ""
  echo "  -h, -?, --help                Show this help message."
  echo ""
  echo "--------------------------------------------"
  footerInfo
}

# If user passed help flag
if [ "$SHOW_HELP" == 1 ]; then
  showHelp
  exit
# If user passed version flag
elif [ "$SHOW_VERSION" == 1 ]; then
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
if [ -z "$USER_OLD_EMAIL" ] && [ "$SHOULD_EXECUTE" == 0 ]; then
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
  echo "--------------------------------------------"
  read -p "Email to Replace: ${COLOR_CYAN}" USER_OLD_EMAIL
  echo "${COLOR_RESET}"
elif [ -z "$USER_OLD_EMAIL" ] && [ "$SHOULD_EXECUTE" == 1 ]; then
  echo "${COLOR_RED}ERROR: --old-email is required.${COLOR_RESET}"
  echo "${COLOR_RED}Try again by passing a valid old email address or removing the --force flag."${COLOR_RESET} >&2
  exit 1
fi

if [ -z "$USER_OLD_EMAIL" ]; then
  echo "${COLOR_RED}ERROR: Email to Replace is required.${COLOR_RESET}"
  echo "${COLOR_RED}Try again and be sure to provide a valid email address to replace."${COLOR_RESET} >&2
  exit 1
else
  # Set USER_OLD_EMAIL and transform to lowercase
  USER_OLD_EMAIL=$(echo "$USER_OLD_EMAIL" | awk "{print tolower(\$0)}")
fi

# Check if USER_OLD_EMAIL exists in log
USER_OLD_EMAIL_EXISTS="$(git ${USER_GIT_DIR} ${USER_WORK_TREE} log --pretty=format:"%ae" | grep -wxi ${USER_OLD_EMAIL})"

# If USER_OLD_EMAIL does NOT exist in log
if [ -z "$USER_OLD_EMAIL_EXISTS" ]; then
  # USER_OLD_EMAIL does not exist in log
  echo "${COLOR_YELLOW}The email '${USER_OLD_EMAIL}' does not exist in the commit history for ${COLOR_RESET}"
  echo "${COLOR_YELLOW}this repository. Please check your spelling and try again.${COLOR_RESET}"
  exit 1
fi

# USER_NEW_EMAIL
if [ -z "$USER_NEW_EMAIL" ] && [ "$SHOULD_EXECUTE" == 0 ]; then
  # Prompt user for correct email ( USER_NEW_EMAIL )
  echo ""
  echo "Enter a new/corrected email for this user."
  echo "------------------------------------------"
  read -p "New Email: ${COLOR_CYAN}" USER_NEW_EMAIL
  echo "${COLOR_RESET}"
elif [ -z "$USER_NEW_EMAIL" ] && [ "$SHOULD_EXECUTE" == 1 ]; then
  echo "${COLOR_RED}ERROR: --new-email is required.${COLOR_RESET}"
  echo "${COLOR_RED}A new email address is required. Please try again.${COLOR_RESET}"
  exit 1
fi

if [ -z "$USER_NEW_EMAIL" ]; then
  echo "${COLOR_RED}ERROR: New Email is required.${COLOR_RESET}"
  echo "${COLOR_RED}Try again and be sure to provide a valid new email address."${COLOR_RESET} >&2
  exit 1
else
  # Set USER_NEW_EMAIL and transform to lowercase
  USER_NEW_EMAIL="${USER_NEW_EMAIL}"
fi

# If old email address matches new email address
if [ "$USER_OLD_EMAIL" == "$USER_NEW_EMAIL" ] && [ "$SHOULD_EXECUTE" == 0 ]; then
  # Check if user would like to update a remote repository
  while true; do
    echo "${COLOR_YELLOW}The old email address, '${USER_OLD_EMAIL}' matches the${COLOR_RESET}"
    echo "${COLOR_YELLOW}new email address you provided, '${USER_NEW_EMAIL}'.${COLOR_RESET}"
    echo "${COLOR_YELLOW}If you continue, you will only be updating the name.${COLOR_RESET}"
    echo ""
    read -p "${COLOR_YELLOW}Continue to updating the name only? [y/n]: ${COLOR_CYAN}" UPDATE_NAME
    echo "${COLOR_RESET}"
    case $UPDATE_NAME in
    [Yy]*)
      UPDATE_NAME=1
      break
      ;;
    [Nn]*)
      UPDATE_NAME=0
      break
      ;;
    *)
      echo ""
      echo "   ${COLOR_YELLOW}You must enter 'y' or 'n' to signal if you would like to update just the name.${COLOR_RESET}"
      echo ""
      ;;
    esac
  done
else
  UPDATE_NAME=1
fi

if [ "$UPDATE_NAME" == 0 ]; then
  echo ""
  echo "${COLOR_YELLOW}No changes are necessary.${COLOR_RESET}"
  SHOULD_EXECUTE=0
  exit 1
fi

# USER_NEW_NAME
if [ -z "$USER_NEW_NAME" ] && [ "$SHOULD_EXECUTE" == 0 ]; then
  # Prompt user for correct name ( USER_NEW_NAME )
  echo ""
  echo "Enter the new/corrected first and last name for this user."
  echo "----------------------------------------------------------"
  read -p "New Name: ${COLOR_CYAN}" USER_NEW_NAME
  echo "${COLOR_RESET}"
elif [ -z "$USER_NEW_NAME" ] && [ "$SHOULD_EXECUTE" == 1 ]; then
  echo "${COLOR_RED}ERROR: --new-name is required.${COLOR_RESET}"
  echo "${COLOR_RED}Try again by passing a valid first and last name or removing the --force flag."${COLOR_RESET} >&2
  exit 1
fi

if [ -z "$USER_NEW_NAME" ]; then
  echo "${COLOR_RED}ERROR: New Name is required.${COLOR_RESET}"
  echo "${COLOR_RED}Try again and be sure to provide a valid first and last name."${COLOR_RESET} >&2
  exit 1
else
  USER_NEW_NAME="${USER_NEW_NAME}"
fi

# Get a list of remote repositories, if they exist
ALL_REMOTE_REPOSITORIES=$(git ${USER_GIT_DIR} ${USER_WORK_TREE} remote show)

# If user wants to update remote and remote repositories exist, and user did not force
if [ -z "$UPDATE_REMOTE" ] && [ -n "$ALL_REMOTE_REPOSITORIES" ] && [ "$SHOULD_EXECUTE" == 0 ]; then
  # Check if user would like to update a remote repository
  while true; do
    read -p "Would you like to update a remote repository? [y/n]: ${COLOR_CYAN}" UPDATE_REMOTE
    echo "${COLOR_RESET}"
    case $UPDATE_REMOTE in
    [Yy]*)
      UPDATE_REMOTE=1
      break
      ;;
    [Nn]*)
      UPDATE_REMOTE=0
      break
      ;;
    *)
      echo ""
      echo "   ${COLOR_YELLOW}You must enter 'y' or 'n' to signal if you would like to update a remote repository.${COLOR_RESET}"
      echo ""
      ;;
    esac
  done
elif [ "$SHOULD_EXECUTE" == 1 ] && [ -n "$ALL_REMOTE_REPOSITORIES" ]; then
  # User forced, and remote repositories exist, so set flag
  UPDATE_REMOTE=1
elif [ -z "$ALL_REMOTE_REPOSITORIES" ]; then
  # Remote repositories do not exist, so set flag
  UPDATE_REMOTE=0
fi

# USER_REMOTE
if [ "$UPDATE_REMOTE" == 1 ] && [ -z "$USER_REMOTE" ] && [ "$SHOULD_EXECUTE" == 0 ]; then
  # Prompt user for remote (Default: 'origin' )
  echo ""
  echo "Existing Remote Repositories:"
  echo "--------------------------------------------"
  echo "${COLOR_CYAN}$(git ${USER_GIT_DIR} ${USER_WORK_TREE} remote show)${COLOR_RESET}"
  echo "--------------------------------------------"
  echo ""
  echo "Enter the name of the remote you would like to alter."
  echo "Default: ${COLOR_YELLOW}${DEFAULT_REMOTE}${COLOR_RESET}"
  echo "--------------------------------------------------------"
  read -p "Remote Name [Press enter to use ${COLOR_YELLOW}${DEFAULT_REMOTE}${COLOR_RESET}]: ${COLOR_CYAN}" USER_REMOTE
  USER_REMOTE=${USER_REMOTE:-"$DEFAULT_REMOTE"}
  echo "${COLOR_RESET}"
elif [ -z "$USER_REMOTE" ] && [ "$SHOULD_EXECUTE" == 1 ]; then
  # Running non-interactive, so set to default
  USER_REMOTE="$DEFAULT_REMOTE"
  echo ""
  echo "${COLOR_YELLOW}--remote flag not present... proceeding with default remote '${USER_REMOTE}'.${COLOR_RESET}"
fi

# Double-check that USER_REMOTE is set
if [ -z "$USER_REMOTE" ]; then
  USER_REMOTE="${DEFAULT_REMOTE}"
else
  USER_REMOTE="${USER_REMOTE}"
fi

if [ "$UPDATE_REMOTE" == 1 ]; then
  # Check if USER_REMOTE exists
  USER_REMOTE_EXISTS="$(git ${USER_GIT_DIR} ${USER_WORK_TREE} remote show | grep -wxi ${USER_REMOTE})"
  # Get the remote repository URL, if there is one
  REMOTE_REPOSITORY=$(git ${USER_GIT_DIR} ${USER_WORK_TREE} config --get remote.${USER_REMOTE}.url)

  # If USER_REMOTE does NOT exist
  if [ -z "$USER_REMOTE_EXISTS" ] || [ -z "$REMOTE_REPOSITORY" ]; then
    echo ""
    echo "${COLOR_YELLOW}The remote '${USER_REMOTE}' does not exist in this repository. ${COLOR_RESET}"
    echo "${COLOR_YELLOW}You may run 'git remote show' to view available remotes, and then try again.${COLOR_RESET}"
    echo ""
    SHOULD_EXECUTE=0
    exit 1
  fi
fi

# Have user verify repository
if [ "$UPDATE_REMOTE" == 1 ] && [ -n "$USER_REMOTE_EXISTS" ] && [ -n "$REMOTE_REPOSITORY" ] && [ "$REPOSITORY_VERIFIED" == 0 ]; then
  while true; do
    echo ""
    echo "Please verify that the remote repository shown below is correct:"
    echo "Remote URL: ${COLOR_YELLOW}${REMOTE_REPOSITORY}${COLOR_RESET}"
    echo "--------------------------------------------------------"
    read -p "${COLOR_RED}Is this the correct repository? [y/n]: ${COLOR_CYAN}" USER_CONFIRM
    echo "${COLOR_RESET}"
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
      echo "   ${COLOR_YELLOW}You must enter 'y' to verify the repository, or 'n' to cancel${COLOR_RESET}"
      echo ""
      ;;
    esac
  done
fi

# Have the user confirm before executing (if they didn't already cancel)
if [ "$SHOULD_EXECUTE" == 0 ] && { [ "$REPOSITORY_VERIFIED" == 1 ] || [ "$UPDATE_REMOTE" == 0 ]; }; then
  while true; do
    echo ""
    echo "Are you sure you want to rewrite the entire"
    echo "history of this Git repository?"
    echo "-------------------------------------------"
    echo "Old email:  ${COLOR_CYAN}${USER_OLD_EMAIL}${COLOR_RESET}"
    echo "New email:  ${COLOR_CYAN}${USER_NEW_EMAIL}${COLOR_RESET}"
    echo "New name:   ${COLOR_CYAN}${USER_NEW_NAME}${COLOR_RESET}"
    if [ "$UPDATE_REMOTE" == 1 ] && [ -n "$USER_REMOTE" ] && [ -n "$REMOTE_REPOSITORY" ]; then
      echo "Remote:     ${COLOR_CYAN}${USER_REMOTE}${COLOR_RESET}"
      echo "Remote URL: ${COLOR_CYAN}${REMOTE_REPOSITORY}${COLOR_RESET}"
    fi
    echo ""
    echo "${COLOR_YELLOW}Note: Running this script rewrites history for all${COLOR_RESET}"
    echo "${COLOR_YELLOW}repository collaborators. Any person with forks ${COLOR_RESET}"
    echo "${COLOR_YELLOW}or clones must fetch the rewritten history and${COLOR_RESET}"
    echo "${COLOR_YELLOW}rebase any local changes into the rewritten history.${COLOR_RESET}"
    echo ""
    read -p "${COLOR_RED}Continue? [y/n]: ${COLOR_CYAN}" USER_CONFIRM
    echo "${COLOR_RESET}"
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
      echo "   ${COLOR_YELLOW}You must enter 'y' to confirm, or 'n' to cancel${COLOR_RESET}"
      echo ""
      ;;
    esac
  done
fi

echo ""

# If SHOULD_EXECUTE is true, and REPOSITORY_VERIFIED is true, rewrite repo history, otherwise, exit
if [ "$SHOULD_EXECUTE" == 1 ]; then
  # Alter commits and rewrite history
  git ${USER_GIT_DIR:+-$USER_GIT_DIR} ${USER_WORK_TREE:+-$USER_WORK_TREE} filter-branch -f --env-filter '
    if [ "$(echo "$GIT_COMMITTER_EMAIL" | awk "{print tolower(\$0)}")" = "'"$USER_OLD_EMAIL"'" ]
    then
        export GIT_COMMITTER_NAME="'"$USER_NEW_NAME"'"
        export GIT_COMMITTER_EMAIL="'"$USER_NEW_EMAIL"'"
    fi
    if [ "$(echo "$GIT_AUTHOR_EMAIL" | awk "{print tolower(\$0)}")" = "'"$USER_OLD_EMAIL"'" ]
    then
        export GIT_AUTHOR_NAME="'"$USER_NEW_NAME"'"
        export GIT_AUTHOR_EMAIL="'"$USER_NEW_EMAIL"'"
    fi
    ' --tag-name-filter cat -- --branches --tags

  # Show Success Message
  echo ""
  echo "${COLOR_GREEN}Successfully updated local commit author info.${COLOR_RESET}"

  # If user wants to update remote and the remote is verified
  if [ "$UPDATE_REMOTE" == 1 ] && [ -n "$REPOSITORY_VERIFIED" ]; then
    echo ""
    echo "Preparing to push to remote '${USER_REMOTE}'..."
    echo ""
    echo "${COLOR_YELLOW}You have 5 seconds to cancel (Ctrl + C)${COLOR_RESET}"
    echo ""
    # Sleep to let user cancel
    sleep 5

    # Update Remote
    git ${USER_GIT_DIR:+-$USER_GIT_DIR} ${USER_WORK_TREE:+-$USER_WORK_TREE} push --force --tags "$USER_REMOTE" 'refs/heads/*'

    echo ""
    echo "${COLOR_GREEN}Successfully updated remote commit author info.${COLOR_RESET}"
    echo ""
    echo "The commits linked to '${COLOR_CYAN}${USER_OLD_EMAIL}${COLOR_RESET}' have"
    echo "been updated to '${COLOR_CYAN}${USER_NEW_NAME} <${USER_NEW_EMAIL}>${COLOR_RESET}' and"
    echo "the changes have been pushed to remote '${COLOR_CYAN}${USER_REMOTE}${COLOR_RESET}'."
  fi
else
  # User Cancelled
  echo "${COLOR_YELLOW}Changes Cancelled.${COLOR_RESET}"
  echo "${COLOR_YELLOW}No changes were pushed to remote '${USER_REMOTE}'.${COLOR_RESET}"
fi

# Reset global vars
REPOSITORY_VERIFIED=0
SHOULD_EXECUTE=0
UPDATE_REMOTE=0
# Reset git environment variables
USER_GIT_DIR=
USER_WORK_TREE=
