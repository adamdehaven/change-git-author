# Change Git Author
---

### Usage Instructions
1. Navigate to your repository
```shell
    cd path/to/repo
```
2. Run the script
```shell
    bash ./changeauthor.sh
```

3. You'll be prompted with configuration options, after which, the script will update your local repository and push the changes to the specified remote:
```shell
#
#    Change Author for Existing Commits
#    ----------------------------------
#
#    1. Enter the email address of the author you
#       would like to replace in the commit history.
#
#       Email to Replace: emmett.brown@example.com
#
#    2. Enter a new/corrected email for this user.
#
#       New Email: marty.mcfly@example.com
#
#    3. Enter the new/corrected name for this user.
#       (Be sure to enclose name in quotes)
#
#       New Name: "Marty McFly"
#
#    4. Enter the remote you would like to alter.
#       (Default: origin)
#
#       Remote Name: origin
#
#    5. Are you sure you want to rewrite the entire
#       history of your Git repository?
#
#       Note: Running this script rewrites history for all
#       repository collaborators. Any person with forks
#       or clones must fetch the rewritten history and
#       rebase any local changes into the rewritten history.
#
#       [y/n]: y
#
#    [Rewrite messages...]
#
#    Successfully Updated Local Author Info
#
#    Preparing to push to remote 'origin'...
#    (Now is your chance to cancel)
#
#    Successfully Updated Remote Author Info
#
#    The author info for commits linked to
#    'emmett.brown@example.com' have been updated to
#    'Marty McFly <marty.mcfly@example.com>' and the changes
#    have been pushed to remote 'origin'.
```

Source script from [GitHub.com](https://help.github.com/articles/changing-author-info/)