# 调用配置文件
. ./config.sh

function log_line()
{
	echo "========"
}

# 获取组件所在的文件夹和组件文件的路径
TMP_MODULE_PATH=""
TMP_MODULE_ADDRESS=""

function get_module_path()
{
	TMP_MODULE_PATH="${WORK_DIR}${ATTACH_DIR_PATH[$1]}"
}

function get_module_address()
{
	TMP_MODULE_ADDRESS="${WORK_DIR}${ATTACH_DIR_PATH[$1]}${MODULES[$1]}${SUFFIX}"
}


if [[ ${#MODULES[*]} != ${#ATTACH_DIR_PATH[*]} ]]; then
	echo "组件名数组和附加路径数组数量不一致!检查配置文件!"
	exit
fi

echo "组件总数量: ${#MODULES[*]}"

# 标识文件是否存在
IS_Exists=false
function file_exists()
{
	if [ -e $1 ]; then
		IS_Exists=true
	else
		IS_Exists=false
	fi
}

# 遍历所有组件名 判断文件是否存在 并展示
MODULES_COUNT=${#MODULES[*]}
NO=0
for (( i = 0; i < MODULES_COUNT; i++ )); do
	# 角标+1获取编号
	NO=`expr $i + 1`
	# 获取组件路径
	get_module_address $i
	# 判断文件是否存在
	file_exists $TMP_MODULE_ADDRESS
	# 打印展示 打印全路径或者只打印module名
	# MODULE_PODSPEC="${NO}. ${TMP_MODULE_ADDRESS}"
	MODULE_PODSPEC="${NO}. ${MODULES[$i]}"
	if [[ $IS_Exists == true ]]; then
		echo "${MODULE_PODSPEC}"
	else
		echo "${MODULE_PODSPEC} (文件未找到)"
	fi
done

log_line

# 获取输入的组件编号
echo "请输入组件编号:"
read READ_INDEX

# 输入的数值-1转换成数组需要的角标
INDEX=`expr $READ_INDEX - 1`

log_line

echo "选择的组件: ${MODULES[$INDEX]}"

# 重新获取路径和文件地址
get_module_path INDEX
# echo $TMP_MODULE_PATH
get_module_address INDEX
# echo $TMP_MODULE_ADDRESS

# 判断文件是否存在 不存在直接退出
file_exists $TMP_MODULE_ADDRESS
# echo $TMP_MODULE_ADDRESS
# echo $IS_Exists
if [[ $IS_Exists == false ]]; then
	echo "${TMP_MODULE_ADDRESS} 文件未找到"
	exit
fi


PODSPEC_NAME=${MODULES[$INDEX]}
DIR_PATH=$TMP_MODULE_PATH
PODSPEC_PATH=$TMP_MODULE_ADDRESS

# 进入工作目录
cd $DIR_PATH
# 显示当前工作目录的分支号
echo "选择的组件分支: $(git symbolic-ref --short -q HEAD)"

log_line

# 1.0.0 这种版本号
OID_VERSION=''
NEW_VERSION=''
# 真正写在文件中的版本号的那一整行文本内容
OID_TMP_STRING=''
NEW_TMP_STRING=''

# 逐行匹配获取文件中的版本号
while read line
do
    # echo $line
    if [[ $line == s.version* ]]; then
    	# echo $line
    	# 匹配单引号或者双引号
		RE="\'([^\']*)\'"
		RE_DOUBLE="\"([^\"]*)\""
		if [[ $line =~ $RE || $line =~ $RE_DOUBLE ]]; then
			OID_VERSION=${BASH_REMATCH[1]}
			echo "podspec版本号 $OID_VERSION"

			OID_TMP_STRING=$line
			# echo $OID_TMP_STRING
		fi
    	break
    fi
done < $PODSPEC_PATH

log_line

echo "组件仓库最后一次提交的标签版本号是 $(git describe --tags `git rev-list --tags --max-count=1`)"

log_line


echo "请输入需要设置的版本号"
read parameter
NEW_VERSION="$parameter"
# echo "输入的版本号是 ${NEW_VERSION} "

log_line


NEW_TMP_STRING=${OID_TMP_STRING/$OID_VERSION/$NEW_VERSION}

# echo $OID_TMP_STRING
# echo $NEW_TMP_STRING

# pwd
# 将输入的版本号整合成podspec文件中的一行文字 并且整行修改进去
sed -i '' "s/${OID_TMP_STRING}/${NEW_TMP_STRING}/g" $PODSPEC_PATH
echo "原版本号${OID_VERSION} 修改后的版本号${NEW_VERSION}"


echo "====请输入提交注释===="
read parameter
READ_NEW_VERSION="$parameter"

# 如果没有输入注释 那么默认注释是podspec文件版本号
if [[ ${#READ_NEW_VERSION} == 0 ]]; then
	READ_NEW_VERSION=${NEW_VERSION}
	echo ">>>> 未输入注释, 默认使用push的tag号做为注释内容 <<<<"
else
	echo ">>>> 输入的提交注释是 ${READ_NEW_VERSION} <<<<"
fi


SECONDS=0

# 所有修改的文件全量提交
git add .
echo "====正在提交===="
git commit -m "${READ_NEW_VERSION}"
echo "====正在Push===="
git tag -a ${NEW_VERSION} -m "${NEW_VERSION}"
git push --tags
git push
echo "====Push完成===="
log_line

# 默认忽略cocoapods的公有文件夹
echo "检索到以下文件夹, 已忽略"master"文件夹"
ALL_REPO_DIR_NAME=()
# IS_DIR=false
COCOAPODS_PATH=~/.cocoapods/repos/
REPO_DIR_PATH=
for dir in $(ls $COCOAPODS_PATH)
do
    # [ -d $dir ] && echo $dir
    REPO_DIR_PATH=${COCOAPODS_PATH}${dir}
    if [ -d $REPO_DIR_PATH ] && [ $dir != master ] ; then
        # IS_DIR=true
        # else
        # IS_DIR=false
        ALL_REPO_DIR_NAME+=($dir)
        echo ${#ALL_REPO_DIR_NAME[*]}. $dir
        # echo  $dir $IS_DIR
        # echo $dir
    fi
done 

echo "请输入需要Push到的文件夹编号"
read REPO_INDEX
REPO_INDEX=`expr $REPO_INDEX - 1`
# echo ${ALL_REPO_DIR_NAME[${REPO_INDEX}]}
# echo ${PODSPEC_PATH}

pod repo push ${ALL_REPO_DIR_NAME[${REPO_INDEX}]} ${PODSPEC_PATH} ${PUSH_REPO_SOURCE} --allow-warnings --verbose --use-libraries

echo "总共用时: ${SECONDS}s"




