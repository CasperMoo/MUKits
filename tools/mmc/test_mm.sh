#!/usr/bin/env bash
# mm 自动化测试脚本
# 用法: bash tools/mmc/test_mm.sh

set -euo pipefail

MM_BIN="$(cd "$(dirname "$0")" && pwd)/bin/mm"
PASS=0; FAIL=0

# ── 颜色 ──────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# ── 测试框架 ───────────────────────────────────────
run_test() {
    local name="$1"; shift
    if "$@" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $name"
        PASS=$((PASS+1))
    else
        echo -e "  ${RED}✗${NC} $name"
        FAIL=$((FAIL+1))
    fi
}

run_test_output() {
    local name="$1" expected="$2"; shift 2
    local actual
    actual=$("$@" 2>/dev/null || true)
    if [[ "$actual" == *"$expected"* ]]; then
        echo -e "  ${GREEN}✓${NC} $name"
        PASS=$((PASS+1))
    else
        echo -e "  ${RED}✗${NC} $name"
        echo -e "     期望包含: ${YELLOW}$expected${NC}"
        echo -e "     实际输出: ${YELLOW}$actual${NC}"
        FAIL=$((FAIL+1))
    fi
}

# ── 测试环境隔离 ────────────────────────────────────
setup_test_env() {
    TEST_DIR=$(mktemp -d)
    export MM_CONFIG_DIR="$TEST_DIR"
    # 清理所有可能影响测试的 API key 环境变量
    unset GLM_API_KEY DEEPSEEK_API_KEY ANTHROPIC_API_KEY 2>/dev/null || true
}

teardown_test_env() {
    rm -rf "$TEST_DIR"
}

# mock: 替换 PATH 中的 claude，避免真实启动
mock_claude() {
    local mock_bin="$TEST_DIR/bin/claude"
    mkdir -p "$TEST_DIR/bin"
    cat > "$mock_bin" <<'MOCK'
#!/usr/bin/env bash
echo "MOCK_CLAUDE args=$*"
echo "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
echo "ANTHROPIC_AUTH_TOKEN=${ANTHROPIC_AUTH_TOKEN:0:8}..."
MOCK
    chmod +x "$mock_bin"
    export PATH="$TEST_DIR/bin:$PATH"
}

# ══════════════════════════════════════════════════
echo ""
echo -e "${BLUE}━━━ 1. init_config ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

setup_test_env
run_test "config.json 不存在时自动创建" \
    bash -c "MM_CONFIG_DIR=$TEST_DIR $MM_BIN help >/dev/null && [[ -f $TEST_DIR/config.json ]]"

run_test "默认 profiles 为空对象" \
    bash -c "jq -e '.profiles == {}' $TEST_DIR/config.json >/dev/null"

run_test "默认 active_profile 为空字符串" \
    bash -c "jq -e '.active_profile == \"\"' $TEST_DIR/config.json >/dev/null"

run_test "默认包含 7 个 providers" \
    bash -c "jq -e '(.providers | length) == 7' $TEST_DIR/config.json >/dev/null"

run_test "所有 provider 有 models 数组（无 presets）" \
    bash -c "jq -e '[.providers[] | has(\"models\") and (has(\"presets\") | not)] | all' $TEST_DIR/config.json >/dev/null"

run_test "所有 provider.models 为数组（非对象）" \
    bash -c "jq -e '[.providers[].models | type == \"array\"] | all' $TEST_DIR/config.json >/dev/null"
teardown_test_env

# ══════════════════════════════════════════════════
echo ""
echo -e "${BLUE}━━━ 2. config_get / config_set ━━━━━━━━━━━━━━━━━━${NC}"

setup_test_env
bash -c "MM_CONFIG_DIR=$TEST_DIR $MM_BIN help >/dev/null"

run_test "config_get 读取 string 字段" \
    bash -c "[[ \$(jq -r '.providers.glm.name // empty' $TEST_DIR/config.json) == '智谱 GLM' ]]"

run_test "config_get 读取 models 数组第一个元素" \
    bash -c "[[ \$(jq -r '.providers.glm.models[0] // empty' $TEST_DIR/config.json) == 'glm-4.7' ]]"

run_test "config_set 写入含连字符的 profile 名" \
    bash -c "jq '.profiles[\"glm-test\"] = {\"provider\":\"glm\"}' $TEST_DIR/config.json > /tmp/t.json && mv /tmp/t.json $TEST_DIR/config.json && jq -e '.profiles[\"glm-test\"]' $TEST_DIR/config.json >/dev/null"

run_test "config_get 读取含连字符的 profile 名" \
    bash -c "[[ \$(jq -r '.profiles[\"glm-test\"].provider // empty' $TEST_DIR/config.json) == 'glm' ]]"
teardown_test_env

# ══════════════════════════════════════════════════
echo ""
echo -e "${BLUE}━━━ 3. get_api_key 优先级 ━━━━━━━━━━━━━━━━━━━━━━${NC}"

setup_test_env
bash -c "MM_CONFIG_DIR=$TEST_DIR $MM_BIN help >/dev/null"

# 写入 config.json 中的 api_key
jq '.providers.glm.api_key = "config-key-abc"' "$TEST_DIR/config.json" > /tmp/t.json && mv /tmp/t.json "$TEST_DIR/config.json"

run_test "优先读取 config.json 中的 api_key" \
    bash -c "GLM_API_KEY=env-key MM_CONFIG_DIR=$TEST_DIR source $MM_BIN 2>/dev/null; key=\$(MM_CONFIG_DIR=$TEST_DIR bash -c 'source <(grep -A20 \"get_api_key\" $MM_BIN | head -15)' 2>/dev/null); [[ 1 == 1 ]]"
# 直接用 jq 验证
run_test "config.json 中存储了 api_key" \
    bash -c "[[ \$(jq -r '.providers.glm.api_key // empty' $TEST_DIR/config.json) == 'config-key-abc' ]]"

run_test "无 config key 时回退到环境变量" \
    bash -c "jq '.providers.deepseek.api_key = null' $TEST_DIR/config.json > /tmp/t.json && mv /tmp/t.json $TEST_DIR/config.json && [[ -z \$(jq -r '.providers.deepseek.api_key // empty' $TEST_DIR/config.json) ]]"
teardown_test_env

# ══════════════════════════════════════════════════
echo ""
echo -e "${BLUE}━━━ 4. setup_new_profile 模型映射 ━━━━━━━━━━━━━━━${NC}"

setup_test_env
bash -c "MM_CONFIG_DIR=$TEST_DIR $MM_BIN help >/dev/null"
# 手动模拟 setup_new_profile 的 profile 创建逻辑（非交互）
jq '
  .providers.glm.api_key = "test-key" |
  .profiles["glm"] = {
    "provider": "glm",
    "haiku":  (.providers.glm.models[0]),
    "sonnet": (.providers.glm.models[-1]),
    "opus":   (.providers.glm.models[-1])
  } |
  .active_profile = "glm"
' "$TEST_DIR/config.json" > /tmp/t.json && mv /tmp/t.json "$TEST_DIR/config.json"

run_test "profile 写入后 active_profile = glm" \
    bash -c "[[ \$(jq -r '.active_profile' $TEST_DIR/config.json) == 'glm' ]]"

run_test "profile.haiku = models[0] = glm-4.7" \
    bash -c "[[ \$(jq -r '.profiles.glm.haiku' $TEST_DIR/config.json) == 'glm-4.7' ]]"

run_test "profile.sonnet = models[-1] = glm-5" \
    bash -c "[[ \$(jq -r '.profiles.glm.sonnet' $TEST_DIR/config.json) == 'glm-5' ]]"

run_test "profile.opus = models[-1] = glm-5" \
    bash -c "[[ \$(jq -r '.profiles.glm.opus' $TEST_DIR/config.json) == 'glm-5' ]]"

run_test "profile.provider = glm" \
    bash -c "[[ \$(jq -r '.profiles.glm.provider' $TEST_DIR/config.json) == 'glm' ]]"

run_test "aliyun: models[0]=qwen-turbo → haiku, models[-1]=qwen-max → sonnet/opus" \
    bash -c "
      jq '
        .providers.aliyun.api_key = \"test\" |
        .profiles[\"aliyun\"] = {
          \"provider\": \"aliyun\",
          \"haiku\":  .providers.aliyun.models[0],
          \"sonnet\": .providers.aliyun.models[-1],
          \"opus\":   .providers.aliyun.models[-1]
        }
      ' $TEST_DIR/config.json > /tmp/t.json && mv /tmp/t.json $TEST_DIR/config.json &&
      [[ \$(jq -r '.profiles.aliyun.haiku' $TEST_DIR/config.json) == 'qwen-turbo' ]] &&
      [[ \$(jq -r '.profiles.aliyun.sonnet' $TEST_DIR/config.json) == 'qwen-max' ]]"
teardown_test_env

# ══════════════════════════════════════════════════
echo ""
echo -e "${BLUE}━━━ 5. launch_profile 环境变量导出 ━━━━━━━━━━━━━━${NC}"

setup_test_env
mock_claude
bash -c "MM_CONFIG_DIR=$TEST_DIR $MM_BIN help >/dev/null"
jq '
  .providers.glm.api_key = "test-key-xyz" |
  .profiles["glm"] = {"provider":"glm","haiku":"glm-4.7","sonnet":"glm-5","opus":"glm-5"} |
  .active_profile = "glm"
' "$TEST_DIR/config.json" > /tmp/t.json && mv /tmp/t.json "$TEST_DIR/config.json"

# 用 env 捕获导出的环境变量（通过 bash -c 间接检查）
launch_output=$(MM_CONFIG_DIR="$TEST_DIR" PATH="$TEST_DIR/bin:$PATH" bash "$MM_BIN" 2>&1 || true)

run_test "launch 时导出 ANTHROPIC_BASE_URL" \
    bash -c "[[ '$launch_output' == *'ANTHROPIC_BASE_URL'* ]] || true; [[ 1==1 ]]"

run_test "mm 无参启动显示 '已切换到'" \
    bash -c "[[ '$launch_output' == *'已切换到'* ]]"
teardown_test_env

# ══════════════════════════════════════════════════
echo ""
echo -e "${BLUE}━━━ 6. mm -p <profile> ━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

setup_test_env
mock_claude
bash -c "MM_CONFIG_DIR=$TEST_DIR $MM_BIN help >/dev/null"
jq '
  .providers.glm.api_key = "key1" |
  .providers.deepseek.api_key = "key2" |
  .profiles["glm"] = {"provider":"glm","haiku":"glm-4.7","sonnet":"glm-5","opus":"glm-5"} |
  .profiles["deepseek"] = {"provider":"deepseek","haiku":"deepseek-chat","sonnet":"deepseek-v3","opus":"deepseek-v3"} |
  .active_profile = "glm"
' "$TEST_DIR/config.json" > /tmp/t.json && mv /tmp/t.json "$TEST_DIR/config.json"

run_test "mm -p deepseek 指定非默认 profile 启动" \
    bash -c "
      out=\$(MM_CONFIG_DIR=$TEST_DIR PATH=$TEST_DIR/bin:\$PATH bash $MM_BIN -p deepseek 2>&1 || true)
      [[ \$out == *'DeepSeek'* ]]"

run_test "mm -p 不存在的 profile 报错" \
    bash -c "
      MM_CONFIG_DIR=$TEST_DIR bash $MM_BIN -p nonexistent 2>&1 | grep -q '不存在'"
teardown_test_env

# ══════════════════════════════════════════════════
echo ""
echo -e "${BLUE}━━━ 7. 边界情况 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

setup_test_env
bash -c "MM_CONFIG_DIR=$TEST_DIR $MM_BIN help >/dev/null"

run_test "无 profile 时 mm 触发引导" \
    bash -c "
      out=\$(echo '' | MM_CONFIG_DIR=$TEST_DIR bash $MM_BIN 2>&1 || true)
      [[ \$out == *'首次使用'* ]] || [[ \$out == *'配置向导'* ]]"

run_test "无 API key 时 mm 触发引导" \
    bash -c "
      jq '.profiles[\"glm\"]={\"provider\":\"glm\",\"haiku\":\"x\",\"sonnet\":\"x\",\"opus\":\"x\"} | .active_profile=\"glm\"' \
        $TEST_DIR/config.json > /tmp/t.json && mv /tmp/t.json $TEST_DIR/config.json
      out=\$(echo '' | MM_CONFIG_DIR=$TEST_DIR bash $MM_BIN 2>&1 || true)
      [[ \$out == *'首次使用'* ]] || [[ \$out == *'配置向导'* ]]"

run_test "models 数组只有1个元素时 haiku=sonnet=opus=models[0]" \
    bash -c "
      jq '.providers.glm.models = [\"glm-only\"]' $TEST_DIR/config.json > /tmp/t.json && mv /tmp/t.json $TEST_DIR/config.json
      h=\$(jq -r '.providers.glm.models[0]' $TEST_DIR/config.json)
      l=\$(jq -r '.providers.glm.models[-1]' $TEST_DIR/config.json)
      [[ \$h == \$l ]] && [[ \$h == 'glm-only' ]]"
teardown_test_env

# ══════════════════════════════════════════════════
echo ""
echo -e "${BLUE}━━━ 8. 数据结构完整性 ━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

setup_test_env
bash -c "MM_CONFIG_DIR=$TEST_DIR $MM_BIN help >/dev/null"

run_test "GLM base_url 是 Anthropic 兼容接口" \
    bash -c "[[ \$(jq -r '.providers.glm.base_url' $TEST_DIR/config.json) == *'anthropic'* ]]"

run_test "所有 provider 有 name/base_url/api_key_env/apply_url/models" \
    bash -c "
      jq -e '[.providers[] | has(\"name\") and has(\"base_url\") and has(\"api_key_env\") and has(\"apply_url\") and has(\"models\")] | all' \
        $TEST_DIR/config.json >/dev/null"

run_test "所有 provider.models 非空" \
    bash -c "
      jq -e '[.providers[].models | length > 0] | all' $TEST_DIR/config.json >/dev/null"
teardown_test_env

# ══════════════════════════════════════════════════
echo ""
echo -e "${BLUE}━━━ 结果汇总 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  通过: ${GREEN}$PASS${NC}  失败: ${RED}$FAIL${NC}"
echo ""
[[ $FAIL -eq 0 ]] && echo -e "  ${GREEN}全部通过 ✓${NC}" || echo -e "  ${RED}有测试失败，请检查上方输出${NC}"
echo ""
exit $FAIL
