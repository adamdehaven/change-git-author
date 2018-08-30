#!/bin/sh

# Change the Git history of a repository
#
# Note: Running this script rewrites history for all repository collaborators.
# After completing these steps, any person with forks or clones must fetch
# the rewritten history and rebase any local changes into the rewritten history.
# ================================================== #

# Set global SHOULD_EXECUTE function to false so user must confirm
SHOULD_EXECUTE=false

# -----------  SET COLORS  -----------
COLOR_RED=$'\e[31m'
COLOR_CYAN=$'\e[36m'
COLOR_YELLOW=$'\e[93m'
COLOR_GREEN=$'\e[32m'
COLOR_RESET=$'\e[0m'

# Get PID of process to kill later if needed
SCRIPT_PID=$$

echo "#    "
echo "#    Change Author for Existing Commits"
echo "#    ----------------------------------"

# -----------  Prompt user for email to replace ( OLD_EMAIL )  -----------
echo "#    "
echo "#    1. Enter the email address of the author you "
echo "#       would like to replace in the commit history."
echo "#    "
read -e -p "#       Email to Replace: ${COLOR_CYAN}" OLD_EMAIL
echo -e "${COLOR_RESET}#    "
eval OLD_EMAIL="$OLD_EMAIL"

# Check for blank email input
if [ -z "$OLD_EMAIL" ]; then
    echo "#       ${COLOR_RED}An email address is required. Please try again.${COLOR_RESET}"
    echo "#    "
    kill "$SCRIPT_PID"
else
    # Email input is not blank

    # Check if OLD_EMAIL exists in log
    OLD_EMAIL_EXISTS="$(git log --pretty=format:"%ae" | grep -w ${OLD_EMAIL})"

    # If OLD_EMAIL does NOT exist in log
    if [ -z "$OLD_EMAIL_EXISTS" ]; then
        # OLD_EMAIL does not exist in log
        echo "#       ${COLOR_RED}The email '${OLD_EMAIL}' does not${COLOR_RESET}"
        echo "#       ${COLOR_RED}exist in the log. Please check your spelling${COLOR_RESET}"
        echo "#       ${COLOR_RED}and try again.${COLOR_RESET}"
        echo "#    "
        kill "$SCRIPT_PID"
    fi
fi

# -----------  Prompt user for correct email ( CORRECT_EMAIL )  -----------
echo "#    2. Enter a new/corrected email for this user."
echo "#    "
read -e -p "#       New Email: ${COLOR_CYAN}" CORRECT_EMAIL
echo -e "${COLOR_RESET}#    "
eval CORRECT_EMAIL="$CORRECT_EMAIL"

# Check for blank email input
if [ -z "$CORRECT_EMAIL" ]; then
    echo "#       ${COLOR_RED}An email address is required. Please try again.${COLOR_RESET}"
    echo "#    "
    kill "$SCRIPT_PID"
fi

# -----------  Prompt user for correct name ( CORRECT_NAME )  -----------
echo "#    3. Enter the new/corrected name for this user."
echo "#       ${COLOR_YELLOW}(Be sure to enclose name in quotes)${COLOR_RESET}"
echo "#    "
read -e -p "#       New Name: ${COLOR_CYAN}" CORRECT_NAME
echo -e "${COLOR_RESET}#    "
eval CORRECT_NAME="$CORRECT_NAME"

# Check for blank name input
if [ -z "$CORRECT_NAME" ]; then
    echo "#       ${COLOR_RED}A name is required. Please try again.${COLOR_RESET}"
    echo "#    "
    kill "$SCRIPT_PID"
fi

# -----------  Prompt user for remote (Default: 'origin' )  -----------
echo "#    4. Enter the remote you would like to alter."
echo "#       ${COLOR_YELLOW}(Default: origin)${COLOR_RESET}"
echo "#    "
read -e -p "#       Remote Name: ${COLOR_CYAN}" -i "origin" REPO_REMOTE
echo -e "${COLOR_RESET}#    "
eval REPO_REMOTE="${REPO_REMOTE:-origin}"

# Check for blank remote input
if [ -z "$REPO_REMOTE" ]; then
    echo "#       ${COLOR_RED}A remote is required. Please try again.${COLOR_RESET}"
    echo "#    "
    kill "$SCRIPT_PID"
fi

# Check if remote exists in repository
VALID_REMOTES="$(git remote | grep -w ${REPO_REMOTE})"
if [ -z "$VALID_REMOTES" ]; then
    # Remote does not exist
    echo "#       ${COLOR_RED}The remote '${REPO_REMOTE}' does not exist for${COLOR_RESET}"
    echo "#       ${COLOR_RED}this repository. Please check your${COLOR_RESET}"
    echo "#       ${COLOR_RED}spelling and try again.${COLOR_RESET}"
    echo "#    "
    kill "$SCRIPT_PID"
fi

# -----------  Have the user confirm before executing  -----------
# read -e -p "#    ${COLOR_RED}Are you sure you wish to execute this command?${COLOR_RESET} [y/n]" USER_CONFIRM

while true; do
    echo "#    5. ${COLOR_RED}Are you sure you want to rewrite the entire ${COLOR_RESET}"
    echo "#       ${COLOR_RED}history of your Git repository?${COLOR_RESET}"
    echo "#       "
    echo "#       ${COLOR_YELLOW}Note: Running this script rewrites history for all${COLOR_RESET}"
    echo "#       ${COLOR_YELLOW}repository collaborators. Any person with forks ${COLOR_RESET}"
    echo "#       ${COLOR_YELLOW}or clones must fetch the rewritten history and${COLOR_RESET}"
    echo "#       ${COLOR_YELLOW}rebase any local changes into the rewritten history.${COLOR_RESET}"
    echo "#    "
    read -e -p "#       [y/n]: ${COLOR_CYAN}" USER_CONFIRM
    echo -e "${COLOR_RESET}#    "
    case $USER_CONFIRM in
        [Yy]* ) SHOULD_EXECUTE=true; break;;
        [Nn]* ) SHOULD_EXECUTE=false; break;;
        * ) echo "#    "; echo "#       ${COLOR_YELLOW}You must enter 'Y' to confirm, or 'N' to cancel${COLOR_RESET}"; echo "#    ";;
    esac
done

# -----------  If SHOULD_EXECUTE is true, rewrite repo history, otherwise, kill  -----------
if [ "$SHOULD_EXECUTE" = true ] ; then
    # -----------  Alter commits and rewrite history  -----------
    git filter-branch --env-filter '
    if [ "$GIT_COMMITTER_EMAIL" = "'"$OLD_EMAIL"'" ]
    then
        export GIT_COMMITTER_NAME="'"$CORRECT_NAME"'"
        export GIT_COMMITTER_EMAIL="'"$CORRECT_EMAIL"'"
    fi
    if [ "$GIT_AUTHOR_EMAIL" = "'"$OLD_EMAIL"'" ]
    then
        export GIT_AUTHOR_NAME="'"$CORRECT_NAME"'"
        export GIT_AUTHOR_EMAIL="'"$CORRECT_EMAIL"'"
    fi
    ' --tag-name-filter cat -- --branches --tags

    # -----------  Show Success Message  -----------
    echo "#    "
    echo "#    ${COLOR_GREEN}Successfully Updated Local Author Info${COLOR_RESET}"
    echo "#    "
    echo "#    Preparing to push to remote '${REPO_REMOTE}'..."
    echo "#    ${COLOR_YELLOW}(Now is your chance to cancel)${COLOR_RESET}"
    echo "#    "
    # Sleep for a sec to let user cancel
    sleep 5

    # -----------  Update Remote  -----------
    git push --force --tags "$REPO_REMOTE" 'refs/heads/*'

    echo "#    "
    echo "#    ${COLOR_GREEN}Successfully Updated Remote Author Info${COLOR_RESET}"
    echo "#    "
    echo "#    ${COLOR_GREEN}The author info for commits linked to${COLOR_RESET}"
    echo "#    ${COLOR_GREEN}'${OLD_EMAIL}' have been updated to${COLOR_RESET}"
    echo "#    ${COLOR_GREEN}'${CORRECT_NAME} <${CORRECT_EMAIL}>' and the changes${COLOR_RESET}"
    echo "#    ${COLOR_GREEN}have been pushed to remote '${REPO_REMOTE}'. ${COLOR_RESET}"
else
    # -----------  User Canceled  -----------
    echo "#    "
    echo "#    ${COLOR_GREEN}Successfully Canceled.${COLOR_RESET}"
    echo "#    ${COLOR_GREEN}No changes were made.${COLOR_RESET}"
fi
