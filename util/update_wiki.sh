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
    # 提取变体名称（如 linux64-gpl-6.1）
    VARIANT="$(basename "${f%.txt}")"

    echo >> "${WIKIPATH}/${WIKIFILE}"
    echo "### ${VARIANT}" >> "${WIKIPATH}/${WIKIFILE}"
    
    # 初始化格式标记
    has_7z=false
    has_zip=false
    has_tar_xz=false
    
    # 读取文件内的所有文件名
    while IFS= read -r FILENAME; do
        # 清理换行符和空格
        FILENAME_CLEAN="$(echo "$FILENAME" | tr -d '\n\r' | xargs)"
        
        # 跳过空行
        if [[ -z "$FILENAME_CLEAN" ]]; then
            continue
        fi
        
        # 根据格式设置标记
        if [[ "$FILENAME_CLEAN" == *.7z ]]; then
            has_7z=true
            _7z_file="$FILENAME_CLEAN"
        elif [[ "$FILENAME_CLEAN" == *.zip ]]; then
            has_zip=true
            zip_file="$FILENAME_CLEAN"
        elif [[ "$FILENAME_CLEAN" == *.tar.xz ]]; then
            has_tar_xz=true
            tar_xz_file="$FILENAME_CLEAN"
        fi
    done < "$f"

    # 按格式优先级输出链接（Windows在前，Linux在后）
    if [[ "$has_7z" == true ]]; then
        echo "[7Z] [下载链接](https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAGNAME}/${_7z_file})" >> "${WIKIPATH}/${WIKIFILE}"
    fi
    if [[ "$has_zip" == true ]]; then
        echo "[ZIP] [下载链接](https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAGNAME}/${zip_file})" >> "${WIKIPATH}/${WIKIFILE}"
    fi
    if [[ "$has_tar_xz" == true ]]; then
        echo "[TAR.XZ] [下载链接](https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAGNAME}/${tar_xz_file})" >> "${WIKIPATH}/${WIKIFILE}"
    fi
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
