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
> "${WIKIPATH}/${WIKIFILE}" # 清空旧内容

for f in "${INPUTS}"/*.txt; do
    # 提取基础变体名（如 win64-lgpl-shared-6.1）
    VARIANT_BASE="$(basename "${f%.txt}")"
    
    # 读取并处理每个文件名
    while IFS= read -r FILENAME; do
        # 清理换行符和空格
        FILENAME_CLEAN="$(echo "$FILENAME" | tr -d '\n\r' | xargs)"
        
        # 校验文件名格式 (文献[6]文件名规范)
        if [[ ! "$FILENAME_CLEAN" =~ ^ffmpeg-.*\.(7z|zip|tar\.xz)$ ]]; then
            continue
        fi
        
        # 提取压缩格式标签
        case "$FILENAME_CLEAN" in
            *.7z)    FORMAT="[7Z]" ;;
            *.zip)   FORMAT="[ZIP]" ;;
            *.tar.xz) FORMAT="[TAR.XZ]" ;;
            *)       continue ;;
        esac
        
        # 生成标准链接（文献[3]的路径规范）
        echo "${FORMAT}${VARIANT_BASE}](https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAGNAME}/${FILENAME_CLEAN})" >> "${WIKIPATH}/${WIKIFILE}"
    done < "$f"
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
