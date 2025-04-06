git filter-branch -f --env-filter '
OLD_EMAIL=""
OLD_EMAIL2=""
NEW_NAME=""
NEW_EMAIL=""
NOREPLY_EMAIL=""
NOREPLY_EMAIL2=""
COAUTHOR_EMAIL=""

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ] || [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL2" ] ; then
    export GIT_COMMITTER_NAME="$NEW_NAME"
    export GIT_COMMITTER_EMAIL="$NEW_EMAIL"
fi

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ] || [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL2" ] ; then
    export GIT_AUTHOR_NAME="$NEW_NAME"
    export GIT_AUTHOR_EMAIL="$NEW_EMAIL"
fi
' --commit-filter '
    # Remove parent, tree, author, committer details
    ORIGINAL_COMMIT_MESSAGE=$(git cat-file commit "$GIT_COMMIT" | sed -n "/^$/,\$p" | sed "1d")

    # Remove the specific co-author line from the commit message
    MODIFIED_COMMIT_MESSAGE=$(echo "$ORIGINAL_COMMIT_MESSAGE" | sed "/<>/d")

    # Create a new commit with the modified message
    git commit-tree "$@" -m "$MODIFIED_COMMIT_MESSAGE"
' --tag-name-filter cat -- --branches --tags
