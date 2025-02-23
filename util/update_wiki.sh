#!/bin/bash
set -e

# 参数检查
if [[ $# != 2 ]]; then
    echo "缺少参数"
    exit -1
fi

# 环境检查
if [[ -z "$GITHUB_REPOSITORY" || -z "$GITHUB_TOKEN" || -z "$GITHUB_ACTOR" ]]; then
    echo "缺少环境变量"
    exit -1
fi

INPUTS="$1"
TAGNAME="$2"

WIKIPATH="tmp_wiki"
WIKIFILE="Latest.md"

# 克隆Wiki仓库
git clone "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.wiki.git" "${WIKIPATH}"

# 生成文档头
echo "# Latest Autobuilds" > "${WIKIPATH}/${WIKIFILE}"

# 遍历所有构建文件
for f in "${INPUTS}"/*.txt; do
    FILENAME=$(basename "$f" .txt)
    VARIANT="$FILENAME"
    LINK_NAME="$VARIANT"

    # Windows架构处理（根据文献[4][9]的压缩格式规范）
    if [[ "$VARIANT" == *"win"* ]]; then
        # 提取压缩格式（最后一段后缀）
        FORMAT=$(echo "$VARIANT" | awk -F'-' '{print $NF}')
        # 去除格式后缀得到架构名（文献[8]的字符串处理方式）
        ARCH=$(echo "$VARIANT" | sed "s/-${FORMAT}$//")
        
        # 格式化链接名称（文献[3]的代码格式化思路）
        case "$FORMAT" in
            "zip") LINK_NAME="[ZIP]${ARCH}" ;;
            "7z")  LINK_NAME="[7Z]${ARCH}" ;;
            *)     LINK_NAME="$ARCH (未知格式)" ;;
        esac
    fi

    # 生成下载链接（文献[10][11]的GitHub链接格式）
    echo >> "${WIKIPATH}/${WIKIFILE}"
    echo "[${LINK_NAME}](https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAGNAME}/$(cat "${f}"))" >> "${WIKIPATH}/${WIKIFILE}"
done

# 提交变更（文献[1]的Git操作流程）
cd "${WIKIPATH}"
git config user.email "actions@github.com"
git config user.name "Github Actions"
git add "$WIKIFILE"
git commit -m "更新最新版本信息"
git push

# 清理
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
