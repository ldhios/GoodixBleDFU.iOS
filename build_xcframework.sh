# --- 配置 ---

# 1. 你的 .xcworkspace 文件的名称 (不包含 .xcworkspace 扩展名)
#    例如: 如果你的文件是 "MyApplication.xcworkspace", 就设置为 "MyApplication"
XCWORKSPACE_FILENAME="GRDFU" # <<--- 请确认或修改这个值

# 2. 你要构建和归档的 Scheme 的名称
#    这个 Scheme 应该在你上面指定的 .xcworkspace 文件中
SCHEME_TO_BUILD="GRDFUSDK2" 


FRAMEWORK_ACTUAL_PRODUCT_NAME="GRDFUSDK2" 


OUTPUT_BASE_NAME="GRDFUSDK2" 

# --- 路径设置 (通常不需要修改) ---
PROJECT_DIR="." # 假设脚本在项目根目录运行
BUILD_DIR="${PROJECT_DIR}/build"
OUTPUT_DIR="${BUILD_DIR}" # XCFramework 的输出目录

# 清理旧的构建产物
echo "🧼 Cleaning old build artifacts..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# --- iOS 真机归档 ---
echo "📦 Archiving for iOS devices..."
xcodebuild archive \
  -workspace "${PROJECT_DIR}/${XCWORKSPACE_FILENAME}.xcworkspace" \
  -scheme "${SCHEME_TO_BUILD}" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "${BUILD_DIR}/${OUTPUT_BASE_NAME}-iOS.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# --- iOS 模拟器归档 ---
echo "📦 Archiving for iOS Simulator..."
xcodebuild archive \
  -workspace "${PROJECT_DIR}/${XCWORKSPACE_FILENAME}.xcworkspace" \
  -scheme "${SCHEME_TO_BUILD}" \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -archivePath "${BUILD_DIR}/${OUTPUT_BASE_NAME}-iOS-Simulator.xcarchive" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES
  EXCLUDED_ARCHS="x86_64" # <<--- 添加这一行来排除 x86_64 架构


# --- 创建 XCFramework ---
echo "🎁 Creating XCFramework..."
# 现在使用 OUTPUT_BASE_NAME 来定位归档文件，
# 并使用 FRAMEWORK_ACTUAL_PRODUCT_NAME 来定位归档内部的 framework
FRAMEWORK_IOS_PATH="${BUILD_DIR}/${OUTPUT_BASE_NAME}-iOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_ACTUAL_PRODUCT_NAME}.framework"
FRAMEWORK_SIMULATOR_PATH="${BUILD_DIR}/${OUTPUT_BASE_NAME}-iOS-Simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_ACTUAL_PRODUCT_NAME}.framework"

# 构建 xcframwork 命令的参数数组
XCFRAMEWORK_ARGS=()
if [ -d "$FRAMEWORK_IOS_PATH" ]; then
  XCFRAMEWORK_ARGS+=(-framework "$FRAMEWORK_IOS_PATH")
else
  echo "Warning: iOS framework not found at ${FRAMEWORK_IOS_PATH}"
fi

if [ -d "$FRAMEWORK_SIMULATOR_PATH" ]; then
  XCFRAMEWORK_ARGS+=(-framework "$FRAMEWORK_SIMULATOR_PATH")
else
  echo "Warning: iOS Simulator framework not found at ${FRAMEWORK_SIMULATOR_PATH}"
fi

# 在执行命令前打印参数，用于调试
echo "Debug: FRAMEWORK_IOS_PATH = ${FRAMEWORK_IOS_PATH}"
echo "Debug: FRAMEWORK_SIMULATOR_PATH = ${FRAMEWORK_SIMULATOR_PATH}"

echo "Debug: Checking existence of iOS framework path..."
ls -ld "${FRAMEWORK_IOS_PATH}" || echo "iOS framework path does not exist or is not a directory."

echo "Debug: Checking existence of Simulator framework path..."
ls -ld "${FRAMEWORK_SIMULATOR_PATH}" || echo "Simulator framework path does not exist or is not a directory."

echo "Debug: XCFRAMEWORK_ARGS array contents: ${XCFRAMEWORK_ARGS[@]}"

if [ ${#XCFRAMEWORK_ARGS[@]} -eq 0 ]; then
  echo "Error: No framework paths were added to XCFRAMEWORK_ARGS. Cannot create XCFramework."
  exit 1
fi

xcodebuild -create-xcframework \
  "${XCFRAMEWORK_ARGS[@]}" \
  -output "${OUTPUT_DIR}/${OUTPUT_BASE_NAME}.xcframework"

echo "✅ Successfully created ${OUTPUT_DIR}/${OUTPUT_BASE_NAME}.xcframework"
echo "📄 XCFramework structure:"
find "${OUTPUT_DIR}/${OUTPUT_BASE_NAME}.xcframework" -print | sed -e "s;[^/]*/;|____;g;s;____|; |;g"

echo "🎉 Done!"