#!/bin/bash  
set -e  

# 检查输入参数个数是否为2  
if [[ $# != 2 ]]; then  
    echo "缺少参数"  
    exit -1  
fi  

# 检查环境变量是否为空  
if [[ -z "$GITHUB_REPOSITORY" || -z "$GITHUB_TOKEN" || -z "$GITHUB_ACTOR" ]]; then  
    echo "缺少环境变量"  
    exit -1  
fi  

INPUTS="$1"  # 输入文件夹路径  
TAGNAME="$2"  # 标签名称  

WIKIPATH="tmp_wiki"  # 临时的 Wiki 文件夹  
WIKIFILE="Latest.md"  # 要更新的 Wiki 文件名  
# 克隆 GitHub Wiki 仓库  
git clone "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.wiki.git" "${WIKIPATH}"  

# 写入 Wiki 文件的标题  
echo "# 最新自动构建" > "${WIKIPATH}/${WIKIFILE}"  

# 遍历输入文件夹中的所有 .txt 文件  
for f in "${INPUTS}"/*.txt; do
    FILENAME=$(basename "$f" .txt)
    VARIANT="$FILENAME"
    LINK_NAME="$VARIANT"

    # 处理 Windows 架构的压缩格式
    if [[ "$VARIANT" == *"win"* ]]; then
        # 提取压缩格式（zip 或 7z）
        FORMAT=$(echo "$VARIANT" | awk -F'-' '{print $NF}')
        # 去除压缩格式后缀以获取原始架构名
        ARCH=$(echo "$VARIANT" | sed "s/-${FORMAT}$//")
        # 根据压缩类型添加前缀
        case "$FORMAT" in
            "zip") LINK_NAME="[ZIP]${ARCH}" ;;
            "7z")  LINK_NAME="[7Z]${ARCH}" ;;
        esac
    fi

    echo >> "${WIKIPATH}/${WIKIFILE}"
    echo "[${LINK_NAME}](https://github.com/${GITHUB_REPOSITORY}/releases/download/${TAGNAME}/$(cat "${f}"))" >> "${WIKIPATH}/${WIKIFILE}"
done

# 提交更改到 GitHub Wiki  
cd "${WIKIPATH}"  
git config user.email "actions@github.com"  
git config user.name "Github Actions"  
git add "$WIKIFILE"  
git commit -m "更新最新版本信息"  
git push  

# 清理临时文件夹  
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
