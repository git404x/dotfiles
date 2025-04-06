#!/usr/bin/env bash

echo "Enter no of commits to rebase"
read commits

# start rebase
git rebase -i HEAD~$commits

GITID=""
EMAIL=""
NEW_AUTHOR="<>"

# edit commits
while true; do
  if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then

    # Remove signed off msg
    OG_MSG="$(git cat-file commit HEAD | sed -n "/^$/,\$p" | sed "1d")"
    MOD_MSG=$(echo "$OG_MSG" | sed "/<$EMAIL>/d")

    AUTHOR="$(git show -s --format=%ae HEAD)"
    DATE="$(git show -s --format=%ci HEAD)"

    if [[ "$AUTHOR" == "$GITID+"* && "$AUTHOR" == *@users.noreply.github.com ]] || [[ "$AUTHOR" == "$EMAIL" ]]; then
      export GIT_COMMITTER_DATE="$DATE" && git commit --amend --date="$DATE" --author="$NEW_AUTHOR" -m "$MOD_MSG"
    else
      export GIT_COMMITTER_DATE="$DATE" && git commit --amend --date="$DATE" -m "$MOD_MSG"
    fi

    git rebase --continue

  else
    echo "Rebase completed or no rebase in progress."
    break
  fi
done
