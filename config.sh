# 工作路径
readonly WORK_DIR="/Users/pengpeng/Desktop/"
readonly SUFFIX=".podspec"
# 存放你的Specs的地址, 不填写会导致无法repo push 路径之间用逗号分隔
readonly PUSH_REPO_SOURCE=--sources="http://host.com/iOS/Specs.git,https://github.com/CocoaPods/Specs.git"

# 所有的组件名
MODULES=(
	"PPTestComponent" 
	"PPKit"
	)

# 附加的文件路径 数量必须和上面的Modules对应  没有附加传 "" 既可
ATTACH_DIR_PATH=(
	"GithubTest/PPTestComponent/" 
	""
	)
