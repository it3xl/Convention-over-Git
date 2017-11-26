set -euf +x -o pipefail

echo
echo Start `basename $0`

invoke_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$invoke_path"/set-env.sh "$@"

echo
bash "$env_git_sync"/repo-create.sh "$env_repo_1_path"
bash "$env_git_sync"/repo-create.sh "$env_repo_2_path"


source "$env_git_sync"/changes-detector.sh

declare -a fetch_refs;
declare -a sync_refs;
#declare -A resolve_refs;
for r in $changed_refs; do
  fetch_refs+=("+$r:$r");
  sync_refs+=("$r:$r");
  #resolve_refs+=('"%s" ' "+$r:$r");
done

echo
echo fetch_refs "${fetch_refs[@]}"



# Must use the source command here because it's impossible in bash to export array variables to subscripts.
source "$env_git_sync"/fetching.sh


source "$env_git_sync"/deletion.sh

if [[ $deletion_allowed = 1 ]]; then
  echo '@' 'Deletion (& partial recovering & sync)'
  cd "$env_repo_1_path"
  git push --prune $env_repo_2_url "${env_del_repo1_refspec[@]}" || true
  cd "$env_repo_2_path"
  git push --prune $env_repo_1_url "${env_del_repo2_refspec[@]}" || true


  source "$env_git_sync"/fetching.sh
fi


echo
echo '@ Sync & recovering. Fast-forward. Conventional refs'
cd "$env_repo_1_path"
git push "$env_repo_2_url" "${env_sync_restore_refspec[@]}" || true
cd "$env_repo_2_path"
git push "$env_repo_1_url" "${env_sync_restore_refspec[@]}" || true


source "$env_git_sync"/fetching.sh


echo
echo '@ Conflict resolving (conventional refs).'
cd "$env_repo_1_path"
git push "$env_repo_2_url" "${env_resolv_repo1_refspec[@]}" || true
cd "$env_repo_2_path"
git push "$env_repo_1_url" "${env_resolv_repo2_refspec[@]}" || true


echo End `basename $0`































