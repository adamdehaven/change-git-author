# Change Git Author

This action is destructive to your repository's history. If you're collaborating on a repository with others, it's considered bad practice to rewrite published history.

**You should only do this in an emergency.**

Running this script rewrites history for all repository collaborators. After completing these steps, any person with forks or clones must fetch the rewritten history and rebase any local changes into the rewritten history.

## Usage

1. [Download the script](https://github.com/adamdehaven/change-git-author) from GitHub and save it to an easily-accessible directory on your computer.
2. Change the permissions of the script file to allow it to execute:

    ``` sh
    chmod +x /path/to/changeauthor.sh
    ```

3. Navigate into the repository with the incorrect commit history

    ``` sh
    cd path/to/repo
    ```

    Alternatively, you can run from anywhere by passing the `--git-dir` and `--work-tree` flags.

4. Run the script (with or without flags)

    ``` sh
    ./changeauthor.sh [OPTIONS]...
    ```

    If you did not change the permissions to allow execution, you can also call the script with either of the following:

    ``` sh
    bash ./changeauthor.sh [OPTIONS]...

    sh ./changeauthor.sh [OPTIONS]...
    ```

    If you run the script with no [option flags](#options), you will be prompted for the needed values via interactive prompts. The script will then proceed to update your local repository and push the changes to the specified remote.

----

If you would like to suppress the git-filter-branch warning, simply add the following line the `~/.bashrc` file on your computer:

``` sh
export FILTER_BRANCH_SQUELCH_WARNING=1
```

If you prefer to set up the script as a function you can call from anywhere, add the following function to your `~/.bashrc` file:

``` sh
function changegitauthor() {
  # Update the path to point to the absolute path of the script on your computer
  bash /c/absolute/path/to/change-git-author/changeauthor.sh "$@"
}
```

## Options

You may pass options (as flags) directly to the script, or pass nothing to run the script in interactive mode.

### old-email

- Usage: `-o`, `--old-email`
- Example: `emmett.brown@example.com`

The old/incorrect email address of the author you would like to replace in the commit history.

### new-email

- Usage: `-e`, `--new-email`
- Example: `marty.mcfly@example.com`

The new/corrected email address to replace in commits matching the [old-email](#old-email) address.

### new-name

- Usage: `-n`, `--new-name`
- Example: `Marty McFly`

The new/corrected name for the new commit author info. (Be sure to enclose name in quotes)

### remote

- Usage: `-r`, `--remote`
- Default: `origin`
- Example: `github`

The name of the repository remote you would like to alter.

### force

- Usage: `-f`, `--force`

Allows the script to run successfully in a non-interactive shell (assuming all required flags are set), bypassing the confirmation prompt.

If you do not pass a value to the `--remote` flag when using `--force`, the default remote (`origin`) will be used.

> **WARNING**
>
> By passing the `--force` flag (along with all other required flags), **there is no turning back**. > Once you start the script, the process will start and can severely damage your repository if used incorrectly.

### git-dir

- Usage: `-d`, `--git-dir`

Set the path to the repository (".git" directory) if it differs from the current directory. It can be an absolute path or relative path to current working directory.

This option should be used in conjunction with the `--work-tree` flag.

### work-tree

- Usage: `-w`, `--work-tree`

Set the path to the working tree. It can be an absolute path or a path relative to the current working directory.

### help

- Usage: `-h`, `-?`, `--help`

Show the help content.

### version

- Usage: `-v`, `-V`, `--version`

Show version information.
