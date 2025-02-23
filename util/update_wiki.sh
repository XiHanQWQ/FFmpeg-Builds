#!/bin/bash
set -euo pipefail

if [[ $# != 2 ]]; then
    echo "Usage: $0 <input-dir> <tag-name>"
    exit 1
fi

INPUTS="$1"
TAGNAME="$2"

# 检查输入目录
if [[ ! -d "$INPUTS" ]]; then
    echo "Error: Input directory '$INPUTS' does not exist"
    exit 1
fi

# 检查环境变量
if [[ -z "$GITHUB_REPOSITORY" || -z "$GITHUB_TOKEN" || -z "$GITHUB_ACTOR" ]]; then
    echo "Missing environment variables"
    exit 1
fi

WIKIPATH="tmp_wiki"
WIKIFILE="Latest.md"

# 克隆 Wiki（带重试）
retry_count=0
max_retries=3
until git clone "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.wiki.git" "${WIKIPATH}"; do
    if [[ $retry_count -ge $max_retries ]]; then
        echo "Error: Failed to clone wiki after $max_retries attempts"
        exit 1
    fi
    echo "Retrying wiki clone..."
    sleep 5
    ((retry_count++))
done

# 生成最新版本页面
echo "# Latest Autobuilds" > "${WIKIPATH}/${WIKIFILE}"
for f in "${INPUTS}"/*.txt; do
    # 提取变体名称（如 win64-lgpl-shared-6.1）
    VARIANT="$(basename "${f%.txt}")"

    echo >> "${WIKIPATH}/${WIKIFILE}"
    echo "### ${VARIANT}" >> "${WIKIPATH}/${WIKIFILE}"
    
    # 初始化格式列表
    _7z_files=()
    zip_files=()
    tar_xz_files=()
    
    # 读取文件内的所有文件名
    while IFS= read -r FILENAME; do
        # 清理换行符和空格
        FILENAME_CLEAN="$(echo "$FILENAME" | tr -d '\n\r' | xargs)"
        
        # 跳过空行
        if [[ -z "$FILENAME_CLEAN" ]]; then
            continue
        fi
        
        # 分类存储文件名
        if [[ "$FILENAME_CLEAN" == *.7z ]]; then
            _7z_files+=("$FILENAME_CLEAN")
        elif [[ "$FILENAME_CLEAN" == *.zip ]]; then
            zip_files+=("$FILENAME_CLEAN")
        elif [[ "$FILENAME_CLEAN" == *.tar.xz ]]; then
            tar_xz_files+=("$FILENAME_CLEAN")
        fi
    done < "$f"

    # 输出所有 7z 链接
    for file in "${_7z_files[@]}"; do
        echo "[7Z] [下载链接](https://github.com/${GITHUB_REPOSITORY}/releases/download/latest/${TAGNAME}/${file})" >> "${WIKIPATH}/${WIKIFILE}"
    done

    # 输出所有 zip 链接
    for file in "${zip_files[@]}"; do
        echo "[ZIP] [下载链接](https://github.com/${GITHUB_REPOSITORY}/releases/download/latest/${TAGNAME}/${file})" >> "${WIKIPATH}/${WIKIFILE}"
    done

    # 输出所有 tar.xz 链接
    for file in "${tar_xz_files[@]}"; do
        echo "[TAR.XZ] [下载链接](https://github.com/${GITHUB_REPOSITORY}/releases/download/latest/${TAGNAME}/${file})" >> "${WIKIPATH}/${WIKIFILE}"
    done
done

# 提交更新
cd "${WIKIPATH}"
git config user.email "actions@github.com"
git config user.name "Github Actions"
git add "$WIKIFILE"

if git commit -m "Update latest version info"; then
    # 推送（带重试）
    retry_count=0
    until git push; do
        if [[ $retry_count -ge $max_retries ]]; then
            echo "Error: Failed to push after $max_retries attempts"
            exit 1
        fi
        echo "Retrying git push..."
        sleep 2
        ((retry_count++))
    done
else
    echo "No changes to commit"
fi

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
