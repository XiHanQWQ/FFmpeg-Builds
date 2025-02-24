#!/bin/bash
set -e

if [[ $# != 2 ]]; then
    echo "Missing arguments: ./script.sh <inputs> <tagname>"
    exit -1
fi

if [[ -z "$GITHUB_REPOSITORY" || -z "$GITHUB_TOKEN" || -z "$GITHUB_ACTOR" ]]; then
    echo "Missing environment variables: GITHUB_REPOSITORY, GITHUB_TOKEN, GITHUB_ACTOR"
    exit -1
fi

INPUTS="$1"
TAGNAME="$2"

WIKIPATH="tmp_wiki"
WIKIFILE="Latest.md"
git clone "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.wiki.git" "${WIKIPATH}"

echo "# Latest Autobuilds" > "${WIKIPATH}/${WIKIFILE}"

# 遍历所有构建文件
for f in "${INPUTS}"/*.{txt,txt}; do
    if [[ ! -f "$f" ]]; then
        echo "Warning: File $f does not exist, skipping..."
        continue
    fi
    FILENAME=$(basename "$f" .txt)
    
    # 获取架构和格式
    VARIANT=$(echo "$FILENAME" | awk -F'-' '{print $1}')
    FORMAT=$(echo "$FILENAME" | awk -F'-' '{print $2}')
    
    LINK_NAME=""
    
    if [[ "$FORMAT" == "zip" || "$FORMAT" == "7z" ]]; then
        LINK_NAME="[${FORMAT^^}]${VARIANT}"
    elif [[ "$FORMAT" == "tar.xz" ]]; then
        LINK_NAME="${VARIANT} (${FORMAT})"
    else
        LINK_NAME="${VARIANT} (unknown format)"
    fi

    # 生成下载链接
    echo >> "${WIKIPATH}/${WIKIFILE}"
    echo "[${LINK_NAME}](https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAGNAME}/$(cat "${f}"))" >> "${WIKIPATH}/${WIKIFILE}"
done

cd "${WIKIPATH}"
git config user.email "actions@github.com"
git config user.name "Github Actions"
git add "$WIKIFILE"
git commit -m "更新最新构建版本信息"

cd ..
rm -rf "$WIKIPATH"

# #!/bin/bash
# set -e

# if [[ $# != 2 ]]; then
#     echo "Missing arguments"
#     exit -1
# fi

# if [[ -z "$GITHUB_REPOSITORY" || -z "$GITHUB_TOKEN" || -z "$GITHUB_ACTOR" ]]; then
#     echo "Missing environment"
#     exit -1
# fi

# INPUTS="$1"
# TAGNAME="$2"

# WIKIPATH="tmp_wiki"
# WIKIFILE="Latest.md"
# git clone "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.wiki.git" "${WIKIPATH}"

# echo "# Latest Autobuilds" > "${WIKIPATH}/${WIKIFILE}"
# for f in "${INPUTS}"/*.txt; do
#     VARIANT="$(basename "${f::-4}")"
#     echo >> "${WIKIPATH}/${WIKIFILE}"
#     echo "[${VARIANT}](https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAGNAME}/$(cat "${f}"))" >> "${WIKIPATH}/${WIKIFILE}"
# done

# cd "${WIKIPATH}"
# git config user.email "actions@github.com"
# git config user.name "Github Actions"
# git add "$WIKIFILE"
# git commit -m "Update latest version info"
# git push

# cd ..
# rm -rf "$WIKIPATH"
