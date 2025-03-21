scripts="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "export const build_time = '`date`';" > $scripts/js/precompilation.js