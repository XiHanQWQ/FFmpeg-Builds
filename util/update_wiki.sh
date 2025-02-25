#!/bin/bash
set -e

# 参数校验与环境检查（保持原逻辑）
if [[ $# != 2 ]]; then
    echo "Missing arguments"
    exit -1
fi
if [[ -z "$GITHUB_REPOSITORY" || -z "$GITHUB_TOKEN" || -z "$GITHUB_ACTOR" ]]; then
    echo "Missing environment"
    exit -1
fi

INPUTS="$1"
TAGNAME="$2"

WIKIPATH="tmp_wiki"
WIKIFILE="Latest.md"
git clone "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.wiki.git" "${WIKIPATH}"

# 生成新版文档
echo "# Latest Autobuilds" > "${WIKIPATH}/${WIKIFILE}"
for f in "${INPUTS}"/*.txt; do
    # 新增：打印当前处理的文件名
    echo "Processing file: $(basename $f)"
    
    # 新增：打印文件内容
    echo "File contents:"
    cat "$f"
    echo "-------------------------"

    VARIANT="$(basename "${f::-4}")"
    echo -e "\n## ${VARIANT}\n" >> "${WIKIPATH}/${WIKIFILE}"
    
    while IFS= read -r filename; do
        [[ -z "$filename" ]] && continue
        echo "- [${filename}](https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAGNAME}/${filename})" >> "${WIKIPATH}/${WIKIFILE}"
    done < "$f"
done

# 提交更新（保持原逻辑）
cd "${WIKIPATH}"
git config user.email "actions@github.com"
git config user.name "Github Actions"
git add "$WIKIFILE"
git commit -m "Update latest version info"
git push

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
