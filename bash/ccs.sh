#!/bin/bash
############################################################
# Claude Code Switch (ccs) - 独立版本
# ---------------------------------------------------------
# 功能: 在不同AI模型之间快速切换
# 支持: Claude, Deepseek, GLM4.5, KIMI2
# 版本: 1.0.0
############################################################

# 脚本颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 安全的颜色输出函数
color_echo() {
    local color="$1"
    shift
    printf "%b%s%b\n" "$color" "$*" "$NC"
}

# 配置文件路径
CONFIG_FILE="$HOME/.ccs_config"
USAGE_STATS_FILE="$HOME/.ccs_usage_stats"
KEY_STATUS_FILE="$HOME/.ccs_key_status"

# 智能加载配置：环境变量优先，配置文件补充
load_config() {
    # 创建配置文件（如果不存在）
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << 'EOF'
# CCS 配置文件
# 请替换为你的实际API密钥
# 注意：环境变量中的API密钥优先级高于此文件

# Deepseek - 单 key 配置（向后兼容）
DEEPSEEK_API_KEY=sk-your-deepseek-api-key
# Deepseek - 多 key 配置（可选，数组格式）
DEEPSEEK_API_KEYS=(sk-your-deepseek-key1 sk-your-deepseek-key2)
# Deepseek - 切换策略: round_robin, load_balance, smart
DEEPSEEK_ROTATION_STRATEGY=round_robin

# GLM4.5 (智谱清言)
GLM_API_KEY=your-glm-api-key
GLM_API_KEYS=(your-glm-key1 your-glm-key2)
GLM_ROTATION_STRATEGY=round_robin

# KIMI2 (月之暗面)
KIMI_API_KEY=your-kimi-api-key
KIMI_API_KEYS=(your-kimi-key1 your-kimi-key2)
KIMI_ROTATION_STRATEGY=round_robin

# LongCat（美团）
LONGCAT_API_KEY=your-longcat-api-key
LONGCAT_API_KEYS=(your-longcat-key1 your-longcat-key2)
LONGCAT_ROTATION_STRATEGY=round_robin

# Qwen（如使用官方 Anthropic 兼容网关）
QWEN_API_KEY=your-qwen-api-key
QWEN_API_KEYS=(your-qwen-key1 your-qwen-key2)
QWEN_ROTATION_STRATEGY=round_robin
# 可选：如果使用官方 Qwen 的 Anthropic 兼容端点，请在此填写
QWEN_ANTHROPIC_BASE_URL=

# Claude API配置（可选，如不配置则使用Claude Pro订阅）
CLAUDE_BASE_URL=https://api.aicodemirror.com/api/claudecode
CLAUDE_API_KEY=your-claude-api-key
CLAUDE_API_KEYS=(your-claude-key1 your-claude-key2)
CLAUDE_ROTATION_STRATEGY=round_robin

# —— 可选：模型ID覆盖（不设置则使用下方默认）——
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_SMALL_FAST_MODEL=deepseek-chat
KIMI_MODEL=kimi-k2-0905-preview
KIMI_SMALL_FAST_MODEL=kimi-k2-0905-preview
QWEN_MODEL=qwen3-next-80b-a3b-thinking
QWEN_SMALL_FAST_MODEL=qwen3-next-80b-a3b-thinking
GLM_MODEL=glm-4.5
GLM_SMALL_FAST_MODEL=glm-4.5-air
CLAUDE_MODEL=claude-sonnet-4-20250514
CLAUDE_SMALL_FAST_MODEL=claude-sonnet-4-20250514
OPUS_MODEL=claude-opus-4-1-20250805
OPUS_SMALL_FAST_MODEL=claude-sonnet-4-20250514
LONGCAT_MODEL=LongCat-Flash-Thinking
LONGCAT_SMALL_FAST_MODEL=LongCat-Flash-Chat

# 备用提供商（仅当且仅当官方密钥未提供时启用）
PPINFRA_API_KEY=your-ppinfra-api-key  # https://api.ppinfra.com/openai/v1/anthropic
EOF
        echo -e "${YELLOW}⚠️  配置文件已创建: $CONFIG_FILE${NC}"
        echo -e "${YELLOW}   请编辑此文件添加你的API密钥${NC}"
        return 1
    fi
    
    # 直接source配置文件（更简单可靠的方式）
    source "$CONFIG_FILE" 2>/dev/null || true
}

# 创建默认配置文件
create_default_config() {
    cat > "$CONFIG_FILE" << 'EOF'
# CCS 配置文件
# 请替换为你的实际API密钥
# 注意：环境变量中的API密钥优先级高于此文件

# Deepseek - 单 key 配置（向后兼容）
DEEPSEEK_API_KEY=sk-your-deepseek-api-key
# Deepseek - 多 key 配置（可选，数组格式）
DEEPSEEK_API_KEYS=(sk-your-deepseek-key1 sk-your-deepseek-key2)
# Deepseek - 切换策略: round_robin, load_balance, smart
DEEPSEEK_ROTATION_STRATEGY=round_robin

# GLM4.5 (智谱清言)
GLM_API_KEY=your-glm-api-key
GLM_API_KEYS=(your-glm-key1 your-glm-key2)
GLM_ROTATION_STRATEGY=round_robin

# KIMI2 (月之暗面)
KIMI_API_KEY=your-kimi-api-key
KIMI_API_KEYS=(your-kimi-key1 your-kimi-key2)
KIMI_ROTATION_STRATEGY=round_robin

# LongCat（美团）
LONGCAT_API_KEY=your-longcat-api-key
LONGCAT_API_KEYS=(your-longcat-key1 your-longcat-key2)
LONGCAT_ROTATION_STRATEGY=round_robin

# Qwen（如使用官方 Anthropic 兼容网关）
QWEN_API_KEY=your-qwen-api-key
QWEN_API_KEYS=(your-qwen-key1 your-qwen-key2)
QWEN_ROTATION_STRATEGY=round_robin
# 可选：如果使用官方 Qwen 的 Anthropic 兼容端点，请在此填写
QWEN_ANTHROPIC_BASE_URL=

# Claude API配置（可选，如不配置则使用Claude Pro订阅）
CLAUDE_BASE_URL=https://api.aicodemirror.com/api/claudecode
CLAUDE_API_KEY=your-claude-api-key
CLAUDE_API_KEYS=(your-claude-key1 your-claude-key2)
CLAUDE_ROTATION_STRATEGY=round_robin

# —— 可选：模型ID覆盖（不设置则使用下方默认）——
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_SMALL_FAST_MODEL=deepseek-chat
KIMI_MODEL=kimi-k2-0905-preview
KIMI_SMALL_FAST_MODEL=kimi-k2-0905-preview
QWEN_MODEL=qwen3-next-80b-a3b-thinking
QWEN_SMALL_FAST_MODEL=qwen3-next-80b-a3b-thinking
GLM_MODEL=glm-4.5
GLM_SMALL_FAST_MODEL=glm-4.5-air
CLAUDE_MODEL=claude-sonnet-4-20250514
CLAUDE_SMALL_FAST_MODEL=claude-sonnet-4-20250514
OPUS_MODEL=claude-opus-4-1-20250805
OPUS_SMALL_FAST_MODEL=claude-sonnet-4-20250514
LONGCAT_MODEL=LongCat-Flash-Thinking
LONGCAT_SMALL_FAST_MODEL=LongCat-Flash-Chat

# 备用提供商（仅当且仅当官方密钥未提供时启用）
PPINFRA_API_KEY=your-ppinfra-api-key  # https://api.ppinfra.com/openai/v1/anthropic
EOF
    echo -e "${YELLOW}⚠️  配置文件已创建: $CONFIG_FILE${NC}"
    echo -e "${YELLOW}   请编辑此文件添加你的API密钥${NC}"
}

# 判断值是否为有效（非空且非占位符）
is_effectively_set() {
    local v="$1"
    if [[ -z "$v" ]]; then
        return 1
    fi
    local lower
    lower=$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')
    case "$lower" in
        *your-*-api-key)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# ============= Key 池管理器 =============

# 兼容性辅助函数：读取命令输出到数组
read_lines_to_array() {
    # 兼容性：避免使用 local -n
    local cmd="$2"
    local arr_name="$1"

    # 清空数组
    eval "$arr_name=()"

    if command -v mapfile >/dev/null 2>&1; then
        eval "mapfile -t $arr_name < <($cmd)"
    else
        # 兼容性解决方案
        while IFS= read -r line; do
            [[ -n "$line" ]] && eval "$arr_name+=(\"$line\")"
        done < <(eval "$cmd")
    fi
}

# 初始化使用统计文件
init_usage_stats() {
    if [[ ! -f "$USAGE_STATS_FILE" ]]; then
        echo '{}' > "$USAGE_STATS_FILE"
    fi
}

# 初始化 key 状态文件
init_key_status() {
    if [[ ! -f "$KEY_STATUS_FILE" ]]; then
        echo '{}' > "$KEY_STATUS_FILE"
    fi
}

# 获取提供商的可用 key 列表
get_available_keys() {
    local provider="$1"
    local keys_var="${provider}_API_KEYS"
    local single_key_var="${provider}_API_KEY"
    local available_keys=()

    # 首先检查数组形式的 keys，使用兼容性方法
    local keys_value=""
    eval "keys_value=\${$keys_var}"

    if [[ -n "$keys_value" ]]; then
        # 尝试作为数组获取
        local temp_array=()
        eval "temp_array=(\${${keys_var}[@]})"

        # 检查是否成功获取数组
        if [[ ${#temp_array[@]} -gt 0 ]]; then
            available_keys=("${temp_array[@]}")
        fi
    fi

    # 如果没有数组形式的 keys，回退到单个 key
    if [[ ${#available_keys[@]} -eq 0 ]]; then
        local single_key_value=""
        eval "single_key_value=\${$single_key_var}"
        if [[ -n "$single_key_value" ]]; then
            available_keys=("$single_key_value")
        fi
    fi

    # 过滤掉无效的 keys
    local valid_keys=()
    for key in "${available_keys[@]}"; do
        if is_effectively_set "$key"; then
            valid_keys+=("$key")
        fi
    done

    printf '%s\n' "${valid_keys[@]}"
}

# 记录 key 使用情况
record_key_usage() {
    local provider="$1"
    local key="$2"
    local success="$3"  # true/false

    init_usage_stats

    local key_id
    key_id=$(echo "$key" | sha256sum | cut -d' ' -f1 | head -c 8)
    local timestamp
    timestamp=$(date +%s)

    # 使用 jq 或简单的 json 处理（如果没有 jq，用简单方法）
    if command -v jq >/dev/null 2>&1; then
        local temp_file
        temp_file=$(mktemp)
        jq --arg provider "$provider" \
           --arg key_id "$key_id" \
           --arg timestamp "$timestamp" \
           --arg success "$success" \
           '.[$provider] //= {} |
            .[$provider][$key_id] //= {"total": 0, "success": 0, "last_used": 0} |
            .[$provider][$key_id].total += 1 |
            .[$provider][$key_id].last_used = ($timestamp | tonumber) |
            if $success == "true" then .[$provider][$key_id].success += 1 else . end' \
           "$USAGE_STATS_FILE" > "$temp_file" && mv "$temp_file" "$USAGE_STATS_FILE"
    else
        # 简单的追加记录方式（不使用 JSON）
        echo "$(date '+%Y-%m-%d %H:%M:%S') $provider $key_id $success" >> "${USAGE_STATS_FILE}.log"
    fi
}

# 标记 key 为失败状态
mark_key_failed() {
    local provider="$1"
    local key="$2"
    local reason="$3"

    init_key_status

    local key_id
    key_id=$(echo "$key" | sha256sum | cut -d' ' -f1 | head -c 8)
    local timestamp
    timestamp=$(date +%s)

    if command -v jq >/dev/null 2>&1; then
        local temp_file
        temp_file=$(mktemp)
        jq --arg provider "$provider" \
           --arg key_id "$key_id" \
           --arg timestamp "$timestamp" \
           --arg reason "$reason" \
           '.[$provider] //= {} |
            .[$provider][$key_id] = {"status": "failed", "reason": $reason, "failed_at": ($timestamp | tonumber)}' \
           "$KEY_STATUS_FILE" > "$temp_file" && mv "$temp_file" "$KEY_STATUS_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') $provider $key_id FAILED $reason" >> "${KEY_STATUS_FILE}.log"
    fi
}

# 检查 key 是否被标记为失败（且未超过重试时间）
is_key_healthy() {
    local provider="$1"
    local key="$2"
    local retry_after_minutes="${3:-30}"  # 默认 30 分钟后重试失败的 key

    init_key_status

    local key_id
    key_id=$(echo "$key" | sha256sum | cut -d' ' -f1 | head -c 8)
    local current_time
    current_time=$(date +%s)

    if command -v jq >/dev/null 2>&1 && [[ -f "$KEY_STATUS_FILE" ]]; then
        local failed_at
        failed_at=$(jq -r --arg provider "$provider" --arg key_id "$key_id" \
                      '.[$provider][$key_id].failed_at // empty' "$KEY_STATUS_FILE" 2>/dev/null)

        if [[ -n "$failed_at" && "$failed_at" != "null" ]]; then
            local time_diff=$(( current_time - failed_at ))
            local retry_seconds=$(( retry_after_minutes * 60 ))
            if (( time_diff < retry_seconds )); then
                return 1  # Still in failed state
            fi
        fi
    fi

    return 0  # Key is healthy or failure has expired
}

# 根据策略选择最佳 key
select_best_key() {
    local provider="$1"
    local strategy="${2:-round_robin}"

    local available_keys
    read_lines_to_array available_keys "get_available_keys \"$provider\""

    if [[ ${#available_keys[@]} -eq 0 ]]; then
        echo ""
        return 1
    fi

    # 过滤健康的 keys
    local healthy_keys=()
    for key in "${available_keys[@]}"; do
        if is_key_healthy "$provider" "$key"; then
            healthy_keys+=("$key")
        fi
    done

    if [[ ${#healthy_keys[@]} -eq 0 ]]; then
        # 如果所有 key 都不健康，返回第一个（可能需要重试）
        echo "${available_keys[0]}"
        return 0
    fi

    case "$strategy" in
        "round_robin")
            select_key_round_robin "$provider" "${healthy_keys[@]}"
            ;;
        "load_balance")
            select_key_load_balance "$provider" "${healthy_keys[@]}"
            ;;
        "smart")
            select_key_smart "$provider" "${healthy_keys[@]}"
            ;;
        *)
            echo "${healthy_keys[0]}"  # 默认返回第一个
            ;;
    esac
}

# 轮询策略选择 key
select_key_round_robin() {
    local provider="$1"
    shift
    local keys=("$@")

    if [[ ${#keys[@]} -eq 1 ]]; then
        echo "${keys[0]}"
        return 0
    fi

    # 使用简单的文件记录当前索引
    local index_file="$HOME/.ccs_${provider}_index"
    local current_index=0

    if [[ -f "$index_file" ]]; then
        current_index=$(cat "$index_file" 2>/dev/null || echo "0")
    fi

    # 确保索引在有效范围内
    current_index=$(( current_index % ${#keys[@]} ))

    # 选择当前 key
    echo "${keys[$current_index]}"

    # 更新索引到下一个
    local next_index=$(( (current_index + 1) % ${#keys[@]} ))
    echo "$next_index" > "$index_file"
}

# 负载均衡策略（选择使用次数最少的 key）
select_key_load_balance() {
    local provider="$1"
    shift
    local keys=("$@")

    init_usage_stats

    local min_usage=999999
    local best_key="${keys[0]}"

    for key in "${keys[@]}"; do
        local key_id
        key_id=$(echo "$key" | sha256sum | cut -d' ' -f1 | head -c 8)

        local usage=0
        if command -v jq >/dev/null 2>&1; then
            usage=$(jq -r --arg provider "$provider" --arg key_id "$key_id" \
                      '.[$provider][$key_id].total // 0' "$USAGE_STATS_FILE" 2>/dev/null || echo "0")
        fi

        if (( usage < min_usage )); then
            min_usage=$usage
            best_key="$key"
        fi
    done

    echo "$best_key"
}

# 智能策略（综合考虑使用次数和成功率）
select_key_smart() {
    local provider="$1"
    shift
    local keys=("$@")

    init_usage_stats

    local best_score=-1
    local best_key="${keys[0]}"

    for key in "${keys[@]}"; do
        local key_id
        key_id=$(echo "$key" | sha256sum | cut -d' ' -f1 | head -c 8)

        local total=1
        local success=1
        if command -v jq >/dev/null 2>&1; then
            total=$(jq -r --arg provider "$provider" --arg key_id "$key_id" \
                      '.[$provider][$key_id].total // 1' "$USAGE_STATS_FILE" 2>/dev/null || echo "1")
            success=$(jq -r --arg provider "$provider" --arg key_id "$key_id" \
                        '.[$provider][$key_id].success // 1' "$USAGE_STATS_FILE" 2>/dev/null || echo "1")
        fi

        # 计算成功率，并考虑使用频率
        local success_rate
        success_rate=$(echo "scale=3; $success / $total" | bc 2>/dev/null || echo "1.0")

        # 智能评分：成功率权重 70%，使用频率权重 30%（越少使用越好）
        local usage_factor
        usage_factor=$(echo "scale=3; 1 / ($total + 1)" | bc 2>/dev/null || echo "1.0")
        local score
        score=$(echo "scale=3; $success_rate * 0.7 + $usage_factor * 0.3" | bc 2>/dev/null || echo "1.0")

        if (( $(echo "$score > $best_score" | bc 2>/dev/null || echo "1") )); then
            best_score=$score
            best_key="$key"
        fi
    done

    echo "$best_key"
}

# 安全掩码工具
mask_token() {
    local t="$1"
    local n=${#t}
    if [[ -z "$t" ]]; then
        echo "[未设置]"
        return
    fi
    if (( n <= 8 )); then
        echo "[已设置] ****"
    else
        echo "[已设置] ${t:0:4}...${t:n-4:4}"
    fi
}

mask_presence() {
    local v_name="$1"
    local v_val="${!v_name}"
    if is_effectively_set "$v_val"; then
        echo "[已设置]"
    else
        echo "[未设置]"
    fi
}

# 显示当前状态（脱敏）
show_status() {
    echo -e "${BLUE}📊 当前模型配置:${NC}"
    echo "   BASE_URL: ${ANTHROPIC_BASE_URL:-'默认 (Anthropic)'}"
    echo -n "   AUTH_TOKEN: "
    mask_token "${ANTHROPIC_AUTH_TOKEN}"
    echo "   MODEL: ${ANTHROPIC_MODEL:-'未设置'}"
    echo "   SMALL_MODEL: ${ANTHROPIC_SMALL_FAST_MODEL:-'未设置'}"
    echo ""
    echo -e "${BLUE}🔧 环境变量状态:${NC}"
    echo "   GLM_API_KEY: $(mask_presence GLM_API_KEY)"
    echo "   KIMI_API_KEY: $(mask_presence KIMI_API_KEY)"
    echo "   LONGCAT_API_KEY: $(mask_presence LONGCAT_API_KEY)"
    echo "   DEEPSEEK_API_KEY: $(mask_presence DEEPSEEK_API_KEY)"
    echo "   QWEN_API_KEY: $(mask_presence QWEN_API_KEY)"
    echo "   PPINFRA_API_KEY: $(mask_presence PPINFRA_API_KEY)"
}

# 显示详细状态（包含所有 key 信息）
show_detailed_status() {
    show_status
    echo ""
    echo -e "${BLUE}🔑 Key 池详细状态:${NC}"

    local providers=("DEEPSEEK" "KIMI" "GLM" "QWEN" "LONGCAT" "CLAUDE")

    for provider in "${providers[@]}"; do
        echo ""
        echo -e "${YELLOW}${provider}:${NC}"

        local available_keys=()
        if command -v mapfile >/dev/null 2>&1; then
            mapfile -t available_keys < <(get_available_keys "$provider")
        else
            # 兼容性解决方案
            while IFS= read -r line; do
                [[ -n "$line" ]] && available_keys+=("$line")
            done < <(get_available_keys "$provider")
        fi

        if [[ ${#available_keys[@]} -eq 0 ]]; then
            echo "   无可用 key"
        else
            echo "   可用 key 数量: ${#available_keys[@]}"
            # 修复变量引用语法
            local strategy_var="${provider}_ROTATION_STRATEGY"
            echo "   策略: ${strategy_var} = ${!strategy_var:-round_robin}"

            local i=1
            for key in "${available_keys[@]}"; do
                local key_display
                key_display=$(mask_token "$key")
                local health_status="健康"
                if ! is_key_healthy "$provider" "$key"; then
                    health_status="失败状态"
                fi
                echo "   [$i] $key_display - $health_status"
                ((i++))
            done
        fi
    done
}

# 显示使用统计
show_usage_stats() {
    printf "%b📈 使用统计:%b\n" "${BLUE}" "${NC}"

    init_usage_stats

    if command -v jq >/dev/null 2>&1 && [[ -f "$USAGE_STATS_FILE" ]]; then
        local providers
        providers=$(jq -r 'keys[]' "$USAGE_STATS_FILE" 2>/dev/null)

        if [[ -z "$providers" ]]; then
            echo "   暂无使用记录"
            return
        fi

        while IFS= read -r provider; do
            [[ -z "$provider" ]] && continue
            echo ""
            printf "%b%s:%b\n" "${YELLOW}" "$provider" "${NC}"

            local keys
            keys=$(jq -r --arg provider "$provider" '.[$provider] | keys[]' "$USAGE_STATS_FILE" 2>/dev/null)

            while IFS= read -r key_id; do
                [[ -z "$key_id" ]] && continue

                local total success last_used
                total=$(jq -r --arg provider "$provider" --arg key_id "$key_id" '.[$provider][$key_id].total // 0' "$USAGE_STATS_FILE" 2>/dev/null)
                success=$(jq -r --arg provider "$provider" --arg key_id "$key_id" '.[$provider][$key_id].success // 0' "$USAGE_STATS_FILE" 2>/dev/null)
                last_used=$(jq -r --arg provider "$provider" --arg key_id "$key_id" '.[$provider][$key_id].last_used // 0' "$USAGE_STATS_FILE" 2>/dev/null)

                local success_rate
                if (( total > 0 )); then
                    success_rate=$(echo "scale=1; $success * 100 / $total" | bc 2>/dev/null || echo "0")
                else
                    success_rate="0"
                fi

                local last_used_str="从未使用"
                if [[ "$last_used" != "0" ]]; then
                    last_used_str=$(date -r "$last_used" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "未知时间")
                fi

                # 检查这个密钥是否还在当前配置中
                local status_indicator=""
                local active_keys
                active_keys=$(get_available_keys "$provider" 2>/dev/null || echo "")
                local found=false

                while IFS= read -r active_key; do
                    [[ -z "$active_key" ]] && continue
                    local active_key_id
                    active_key_id=$(echo "$active_key" | sha256sum | cut -d' ' -f1 | head -c 8)
                    if [[ "$active_key_id" == "$key_id" ]]; then
                        found=true
                        break
                    fi
                done <<< "$active_keys"

                if [[ "$found" == "true" ]]; then
                    status_indicator=" [当前活跃]"
                else
                    status_indicator=" [已移除]"
                fi

                echo "   Key ${key_id}: 总计 $total 次, 成功率 ${success_rate}%, 最后使用: $last_used_str${status_indicator}"
            done <<< "$keys"
        done <<< "$providers"
    else
        if [[ -f "${USAGE_STATS_FILE}.log" ]]; then
            echo "   简单日志模式 (最近 10 条记录):"
            tail -10 "${USAGE_STATS_FILE}.log" | while IFS= read -r line; do
                echo "   $line"
            done
        else
            echo "   暂无使用记录"
        fi
    fi
}

# 手动轮换 key
rotate_key() {
    local provider="$1"

    if [[ -z "$provider" ]]; then
        echo -e "${RED}❌ 请指定提供商名称${NC}"
        echo "   支持的提供商: deepseek, kimi, glm, qwen, longcat"
        return 1
    fi

    # 转换为大写
    provider=$(echo "$provider" | tr '[:lower:]' '[:upper:]')

    local available_keys
    read_lines_to_array available_keys "get_available_keys \"$provider\""

    if [[ ${#available_keys[@]} -le 1 ]]; then
        echo -e "${YELLOW}⚠️  $provider 只有一个或没有可用 key，无需轮换${NC}"
        return 0
    fi

    # 强制轮换到下一个 key
    local current_key
    current_key=$(select_key_round_robin "$provider" "${available_keys[@]}")

    echo -e "${GREEN}✅ 已轮换 $provider 到下一个 key${NC}"
    echo "   下次使用的 Key: $(mask_token "$current_key")"
}

# 测试 key 可用性
test_keys() {
    local provider="$1"

    if [[ -z "$provider" ]]; then
        echo -e "${BLUE}🧪 测试所有提供商的 key...${NC}"
        local providers=("DEEPSEEK" "KIMI" "GLM" "QWEN" "LONGCAT" "CLAUDE")
        for p in "${providers[@]}"; do
            test_keys_for_provider "$p"
            echo ""
        done
    else
        # 转换为大写
        provider=$(echo "$provider" | tr '[:lower:]' '[:upper:]')
        test_keys_for_provider "$provider"
    fi
}

# 测试特定提供商的 key
test_keys_for_provider() {
    local provider="$1"

    echo -e "${YELLOW}测试 $provider keys:${NC}"

    local available_keys
    read_lines_to_array available_keys "get_available_keys \"$provider\""

    if [[ ${#available_keys[@]} -eq 0 ]]; then
        echo "   无可用 key"
        return
    fi

    local i=1
    for key in "${available_keys[@]}"; do
        local key_display
        key_display=$(mask_token "$key")

        # 基本格式检查
        local status=""
        if ! is_effectively_set "$key"; then
            status="❌ 无效格式"
        elif ! is_key_healthy "$provider" "$key"; then
            status="⚠️  标记为失败状态"
        else
            # 进行实际的API测试
            echo -n "   [$i] $key_display - 测试中..."

            local test_result
            test_api_key "$provider" "$key"
            test_result=$?

            # 清除当前行并重新打印结果
            echo -ne "\r\033[K"

            case $test_result in
                0)
                    status="✅ API可用"
                    ;;
                2)
                    status="❌ 认证失败"
                    ;;
                3)
                    status="⚠️  速率限制"
                    ;;
                4)
                    status="🔧 服务器错误"
                    ;;
                *)
                    status="❓ 连接错误"
                    ;;
            esac
        fi

        echo "   [$i] $key_display - $status"
        ((i++))
    done

    echo "   注意: 已进行实际 API 调用测试验证可用性"
}

# 测试单个API密钥的可用性
test_api_key() {
    local provider="$1"
    local api_key="$2"
    local base_url=""
    local auth_header=""

    # 根据提供商设置API端点和认证方式
    case "$provider" in
        "DEEPSEEK")
            base_url="https://api.deepseek.com/anthropic"
            auth_header="x-api-key: $api_key"
            ;;
        "KIMI")
            base_url="https://api.moonshot.cn/anthropic"
            auth_header="x-api-key: $api_key"
            ;;
        "GLM")
            base_url="https://open.bigmodel.cn/api/anthropic"
            auth_header="x-api-key: $api_key"
            ;;
        "LONGCAT")
            base_url="https://api.longcat.chat/anthropic"
            auth_header="x-api-key: $api_key"
            ;;
        "QWEN")
            base_url="${QWEN_ANTHROPIC_BASE_URL:-https://api.ppinfra.com/openai/v1/anthropic}"
            auth_header="Authorization: Bearer $api_key"
            ;;
        "CLAUDE")
            base_url="${CLAUDE_BASE_URL:--https://api.anthropic.com}"
            auth_header="x-api-key: $api_key"
            ;;
        "OPUS")
            base_url="${OPUS_BASE_URL:-https://api.anthropic.com}"
            auth_header="x-api-key: $api_key"
            ;;
        "PPINFRA")
            base_url="https://api.ppinfra.com/openai/v1/anthropic"
            auth_header="Authorization: Bearer $api_key"
            ;;
        *)
            return 1
            ;;
    esac

    # 构造测试请求的JSON payload
    local test_payload='{
        "model": "claude-3-haiku-20240307",
        "max_tokens": 10,
        "messages": [
            {
                "role": "user",
                "content": "Hi"
            }
        ]
    }'

    # 使用curl测试API
    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X POST "$base_url/v1/messages" \
        -H "Content-Type: application/json" \
        -H "$auth_header" \
        -H "anthropic-version: 2023-06-01" \
        -d "$test_payload" \
        --connect-timeout 10 \
        --max-time 30 2>/dev/null)

    local http_code
    http_code=$(echo "$response" | tail -n1)
    local body
    body=$(echo "$response" | sed '$d')

    # 检查HTTP状态码
    case "$http_code" in
        200|201)
            return 0  # 成功
            ;;
        401|403)
            return 2  # 认证失败
            ;;
        429)
            return 3  # 速率限制
            ;;
        500|502|503|504)
            return 4  # 服务器错误
            ;;
        *)
            return 1  # 其他错误
            ;;
    esac
}

# 清理环境变量
clean_env() {
    unset ANTHROPIC_BASE_URL
    unset ANTHROPIC_API_URL
    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_MODEL
    unset ANTHROPIC_SMALL_FAST_MODEL
    unset API_TIMEOUT_MS
    unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC
}

# 切换到Deepseek
switch_to_deepseek() {
    echo -e "${YELLOW}🔄 切换到 Deepseek 模型...${NC}"
    clean_env

    # 获取切换策略
    local strategy="${DEEPSEEK_ROTATION_STRATEGY:-round_robin}"

    # 尝试从多 key 中选择最佳 key
    local selected_key
    selected_key=$(select_best_key "DEEPSEEK" "$strategy")

    if [[ -n "$selected_key" ]]; then
        # 官方 Deepseek 的 Anthropic 兼容端点
        export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
        export ANTHROPIC_API_URL="https://api.deepseek.com/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$selected_key"
        export ANTHROPIC_API_KEY="$selected_key"

        # 获取模型配置
        local ds_model="${DEEPSEEK_MODEL:-deepseek-chat}"
        local ds_small="${DEEPSEEK_SMALL_FAST_MODEL:-deepseek-chat}"
        export ANTHROPIC_MODEL="$ds_model"
        export ANTHROPIC_SMALL_FAST_MODEL="$ds_small"

        # 记录使用情况
        record_key_usage "DEEPSEEK" "$selected_key" "true"

        # 显示选择的 key（掩码）
        local key_display
        key_display=$(mask_token "$selected_key")
        echo -e "${GREEN}✅ 已切换到 Deepseek（官方，策略: $strategy）${NC}"
        echo "   选择的 Key: $key_display"
    elif is_effectively_set "$PPINFRA_API_KEY"; then
        # 备用：PPINFRA Anthropic 兼容
        export ANTHROPIC_BASE_URL="https://api.ppinfra.com/openai/v1/anthropic"
        export ANTHROPIC_API_URL="https://api.ppinfra.com/openai/v1/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$PPINFRA_API_KEY"
        export ANTHROPIC_API_KEY="$PPINFRA_API_KEY"

        local ds_model="${DEEPSEEK_MODEL:-deepseek/deepseek-v3.1}"
        local ds_small="${DEEPSEEK_SMALL_FAST_MODEL:-deepseek/deepseek-v3.1}"
        export ANTHROPIC_MODEL="$ds_model"
        export ANTHROPIC_SMALL_FAST_MODEL="$ds_small"

        echo -e "${GREEN}✅ 已切换到 Deepseek（PPINFRA 备用）${NC}"
    else
        echo -e "${RED}❌ 未检测到 DEEPSEEK_API_KEY 或 DEEPSEEK_API_KEYS，且 PPINFRA_API_KEY 未配置，无法切换${NC}"
        return 1
    fi

    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到Claude Sonnet
switch_to_claude() {
    echo -e "${YELLOW}🔄 切换到 Claude Sonnet 4...${NC}"
    clean_env

    # 获取切换策略
    local strategy="${CLAUDE_ROTATION_STRATEGY:-round_robin}"

    # 检查是否配置了自定义API设置
    if [[ -n "$CLAUDE_BASE_URL" ]]; then
        # API模式：使用自定义BASE_URL和密钥
        local selected_key
        selected_key=$(select_best_key "CLAUDE" "$strategy")

        if [[ -n "$selected_key" ]]; then
            export ANTHROPIC_BASE_URL="$CLAUDE_BASE_URL"
            export ANTHROPIC_API_URL="$CLAUDE_BASE_URL"
            export ANTHROPIC_API_KEY="$selected_key"
            export ANTHROPIC_AUTH_TOKEN=""

            # 获取模型配置
            local claude_model="${CLAUDE_MODEL:-claude-sonnet-4-20250514}"
            local claude_small="${CLAUDE_SMALL_FAST_MODEL:-claude-sonnet-4-20250514}"
            export ANTHROPIC_MODEL="$claude_model"
            export ANTHROPIC_SMALL_FAST_MODEL="$claude_small"

            # 记录使用情况
            record_key_usage "CLAUDE" "$selected_key" "true"

            # 显示选择的 key（掩码）
            local key_display
            key_display=$(mask_token "$selected_key")
            echo -e "${GREEN}✅ 已切换到 Claude Sonnet 4（API模式，策略: $strategy）${NC}"
            echo "   BASE_URL: $ANTHROPIC_BASE_URL"
            echo "   选择的 Key: $key_display"
        else
            echo -e "${RED}❌ 配置了 CLAUDE_BASE_URL 但未找到可用的 API 密钥${NC}"
            return 1
        fi
    else
        # Pro模式：使用Claude Pro订阅（原有逻辑）
        export ANTHROPIC_MODEL="claude-sonnet-4-20250514"
        export ANTHROPIC_SMALL_FAST_MODEL="claude-sonnet-4-20250514"
        echo -e "${GREEN}✅ 已切换到 Claude Sonnet 4（Pro订阅模式）${NC}"
        echo "   使用 Claude Pro 订阅"
    fi

    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到Claude Opus
switch_to_opus() {
    echo -e "${YELLOW}🔄 切换到 Claude Opus 4.1...${NC}"
    clean_env
    export ANTHROPIC_MODEL="claude-opus-4-1-20250805"
    export ANTHROPIC_SMALL_FAST_MODEL="claude-sonnet-4-20250514"
    echo -e "${GREEN}✅ 已切换到 Claude Opus 4.1 (使用 Claude Pro 订阅)${NC}"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到GLM4.5
switch_to_glm() {
    echo -e "${YELLOW}🔄 切换到 GLM4.5 模型...${NC}"
    clean_env

    # 获取切换策略
    local strategy="${GLM_ROTATION_STRATEGY:-round_robin}"

    # 尝试从多 key 中选择最佳 key
    local selected_key
    selected_key=$(select_best_key "GLM" "$strategy")

    if [[ -n "$selected_key" ]]; then
        export ANTHROPIC_BASE_URL="https://open.bigmodel.cn/api/anthropic"
        export ANTHROPIC_API_URL="https://open.bigmodel.cn/api/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$selected_key"
        export ANTHROPIC_API_KEY="$selected_key"

        # 获取模型配置
        local glm_model="${GLM_MODEL:-glm-4.5}"
        local glm_small="${GLM_SMALL_FAST_MODEL:-glm-4.5-air}"
        export ANTHROPIC_MODEL="$glm_model"
        export ANTHROPIC_SMALL_FAST_MODEL="$glm_small"

        # 记录使用情况
        record_key_usage "GLM" "$selected_key" "true"

        # 显示选择的 key（掩码）
        local key_display
        key_display=$(mask_token "$selected_key")
        echo -e "${GREEN}✅ 已切换到 GLM4.5（官方，策略: $strategy）${NC}"
        echo "   选择的 Key: $key_display"
    else
        echo -e "${RED}❌ 未检测到 GLM_API_KEY 或 GLM_API_KEYS。按要求，GLM 不走 PPINFRA 备用，请配置官方密钥${NC}"
        return 1
    fi

    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到KIMI2
switch_to_kimi() {
    echo -e "${YELLOW}🔄 切换到 KIMI2 模型...${NC}"
    clean_env

    # 获取切换策略
    local strategy="${KIMI_ROTATION_STRATEGY:-round_robin}"

    # 尝试从多 key 中选择最佳 key
    local selected_key
    selected_key=$(select_best_key "KIMI" "$strategy")

    if [[ -n "$selected_key" ]]; then
        # 官方 Moonshot KIMI 的 Anthropic 兼容端点
        export ANTHROPIC_BASE_URL="https://api.moonshot.cn/anthropic"
        export ANTHROPIC_API_URL="https://api.moonshot.cn/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$selected_key"
        export ANTHROPIC_API_KEY="$selected_key"

        # 获取模型配置
        local kimi_model="${KIMI_MODEL:-kimi-k2-0905-preview}"
        local kimi_small="${KIMI_SMALL_FAST_MODEL:-kimi-k2-0905-preview}"
        export ANTHROPIC_MODEL="$kimi_model"
        export ANTHROPIC_SMALL_FAST_MODEL="$kimi_small"

        # 记录使用情况
        record_key_usage "KIMI" "$selected_key" "true"

        # 显示选择的 key（掩码）
        local key_display
        key_display=$(mask_token "$selected_key")
        echo -e "${GREEN}✅ 已切换到 KIMI2（官方，策略: $strategy）${NC}"
        echo "   选择的 Key: $key_display"
    elif is_effectively_set "$PPINFRA_API_KEY"; then
        # 备用：PPINFRA Anthropic 兼容
        export ANTHROPIC_BASE_URL="https://api.ppinfra.com/openai/v1/anthropic"
        export ANTHROPIC_API_URL="https://api.ppinfra.com/openai/v1/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$PPINFRA_API_KEY"
        export ANTHROPIC_API_KEY="$PPINFRA_API_KEY"

        local kimi_model="${KIMI_MODEL:-moonshotai/kimi-k2-0905}"
        local kimi_small="${KIMI_SMALL_FAST_MODEL:-moonshotai/kimi-k2-0905}"
        export ANTHROPIC_MODEL="$kimi_model"
        export ANTHROPIC_SMALL_FAST_MODEL="$kimi_small"

        echo -e "${GREEN}✅ 已切换到 KIMI2（PPINFRA 备用）${NC}"
    else
        echo -e "${RED}❌ 未检测到 KIMI_API_KEY 或 KIMI_API_KEYS，且 PPINFRA_API_KEY 未配置，无法切换${NC}"
        return 1
    fi

    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 切换到 Qwen（官方优先，缺省走 PPINFRA）
switch_to_qwen() {
    echo -e "${YELLOW}🔄 切换到 Qwen 模型...${NC}"
    clean_env

    # 获取切换策略
    local strategy="${QWEN_ROTATION_STRATEGY:-round_robin}"

    # 尝试从多 key 中选择最佳 key（官方配置需要 QWEN_ANTHROPIC_BASE_URL）
    local selected_key
    selected_key=$(select_best_key "QWEN" "$strategy")

    if [[ -n "$selected_key" && -n "$QWEN_ANTHROPIC_BASE_URL" ]]; then
        export ANTHROPIC_BASE_URL="$QWEN_ANTHROPIC_BASE_URL"
        export ANTHROPIC_API_URL="$QWEN_ANTHROPIC_BASE_URL"
        export ANTHROPIC_AUTH_TOKEN="$selected_key"
        export ANTHROPIC_API_KEY="$selected_key"

        # 获取模型配置
        local qwen_model="${QWEN_MODEL:-qwen3-next-80b-a3b-thinking}"
        local qwen_small="${QWEN_SMALL_FAST_MODEL:-qwen3-next-80b-a3b-thinking}"
        export ANTHROPIC_MODEL="$qwen_model"
        export ANTHROPIC_SMALL_FAST_MODEL="$qwen_small"

        # 记录使用情况
        record_key_usage "QWEN" "$selected_key" "true"

        # 显示选择的 key（掩码）
        local key_display
        key_display=$(mask_token "$selected_key")
        echo -e "${GREEN}✅ 已切换到 Qwen（官方配置，策略: $strategy）${NC}"
        echo "   选择的 Key: $key_display"
    elif is_effectively_set "$PPINFRA_API_KEY"; then
        export ANTHROPIC_BASE_URL="https://api.ppinfra.com/openai/v1/anthropic"
        export ANTHROPIC_API_URL="https://api.ppinfra.com/openai/v1/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$PPINFRA_API_KEY"
        export ANTHROPIC_API_KEY="$PPINFRA_API_KEY"

        local qwen_model="${QWEN_MODEL:-qwen3-next-80b-a3b-thinking}"
        local qwen_small="${QWEN_SMALL_FAST_MODEL:-qwen3-next-80b-a3b-thinking}"
        export ANTHROPIC_MODEL="$qwen_model"
        export ANTHROPIC_SMALL_FAST_MODEL="$qwen_small"

        echo -e "${GREEN}✅ 已切换到 Qwen（PPINFRA 备用）${NC}"
    else
        echo -e "${RED}❌ 未检测到 QWEN_API_KEY/QWEN_API_KEYS + QWEN_ANTHROPIC_BASE_URL，且 PPINFRA_API_KEY 未配置，无法切换${NC}"
        return 1
    fi

    echo "   BASE_URL: $ANTHROPIC_BASE_URL"
    echo "   MODEL: $ANTHROPIC_MODEL"
    echo "   SMALL_MODEL: $ANTHROPIC_SMALL_FAST_MODEL"
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}🔧 Claude Code Switch 工具 v2.1.0${NC}"
    echo ""
    echo -e "${YELLOW}用法:${NC} $(basename "$0") [选项]"
    echo ""
    echo -e "${YELLOW}模型选项（与 env 等价，输出 export 语句，便于 eval）:${NC}"
    echo "  deepseek, ds       - 等同于: env deepseek"
    echo "  kimi, kimi2        - 等同于: env kimi"
    echo "  longcat, lc        - 等同于: env longcat"
    echo "  qwen               - 等同于: env qwen"
    echo "  glm, glm4          - 等同于: env glm"
    echo "  claude, sonnet, s  - 等同于: env claude"
    echo "  opus, o            - 等同于: env opus"
    echo ""
    echo -e "${YELLOW}工具选项:${NC}"
    echo "  status, st       - 显示当前配置（脱敏显示）"
    echo "  status --detailed- 显示所有 key 的详细状态"
    echo "  env [模型]       - 仅输出 export 语句（用于 eval），不打印密钥明文"
    echo "  config, cfg      - 编辑配置文件"
    echo "  stats            - 显示使用统计"
    echo "  rotate [提供商]  - 手动轮换到下一个 key"
    echo "  test-keys [提供商] - 测试所有 key 的可用性"
    echo "  help, h          - 显示此帮助信息"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  eval \"\$($(basename \"$0\") deepseek)\"      # 在当前 shell 中生效（推荐）"
    echo "  $(basename "$0") status                      # 查看当前状态（脱敏）"
    echo ""
    echo -e "${YELLOW}支持的模型:${NC}"
    echo "  🌙 KIMI2               - 官方：kimi-k2-0905-preview"
    echo "  🤖 Deepseek            - 官方：deepseek-chat ｜ 备用：deepseek/deepseek-v3.1 (PPINFRA)"
echo "  🐱 LongCat             - 官方：LongCat-Flash-Thinking / LongCat-Flash-Chat"
    echo "  🐪 Qwen                - 备用：qwen3-next-80b-a3b-thinking (PPINFRA)"
    echo "  🇨🇳 GLM4.5             - 官方：glm-4.5 / glm-4.5-air"
    echo "  🧠 Claude Sonnet 4     - claude-sonnet-4-20250514"
    echo "  🚀 Claude Opus 4.1     - claude-opus-4-1-20250805"
}

# 将缺失的模型ID覆盖项追加到配置文件（仅追加缺失项，不覆盖已存在的配置）
ensure_model_override_defaults() {
    local -a pairs=(
        "DEEPSEEK_MODEL=deepseek-chat"
        "DEEPSEEK_SMALL_FAST_MODEL=deepseek-chat"
"KIMI_MODEL=kimi-k2-0905-preview"
        "KIMI_SMALL_FAST_MODEL=kimi-k2-0905-preview"
"LONGCAT_MODEL=LongCat-Flash-Thinking"
        "LONGCAT_SMALL_FAST_MODEL=LongCat-Flash-Chat"
        "QWEN_MODEL=qwen3-next-80b-a3b-thinking"
        "QWEN_SMALL_FAST_MODEL=qwen3-next-80b-a3b-thinking"
"GLM_MODEL=glm-4.5"
        "GLM_SMALL_FAST_MODEL=glm-4.5-air"
        "CLAUDE_MODEL=claude-sonnet-4-20250514"
        "CLAUDE_SMALL_FAST_MODEL=claude-sonnet-4-20250514"
        "OPUS_MODEL=claude-opus-4-1-20250805"
        "OPUS_SMALL_FAST_MODEL=claude-sonnet-4-20250514"
    )
    local added_header=0
    for pair in "${pairs[@]}"; do
        local key="${pair%%=*}"
        local default="${pair#*=}"
        if ! grep -Eq "^[[:space:]]*(export[[:space:]]+)?${key}[[:space:]]*=" "$CONFIG_FILE" 2>/dev/null; then
            if [[ $added_header -eq 0 ]]; then
                {
                    echo ""
                    echo "# ---- CCS model ID overrides (auto-added) ----"
                } >> "$CONFIG_FILE"
                added_header=1
            fi
            printf "%s=%s\n" "$key" "$default" >> "$CONFIG_FILE"
        fi
    done
}

# 编辑配置文件
edit_config() {
    # 确保配置文件存在
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${YELLOW}📝 配置文件不存在，正在创建: $CONFIG_FILE${NC}"
        create_default_config
    fi

    # 追加缺失的模型ID覆盖默认值（不触碰已有键）
    ensure_model_override_defaults
    
    echo -e "${BLUE}🔧 打开配置文件进行编辑...${NC}"
    echo -e "${YELLOW}配置文件路径: $CONFIG_FILE${NC}"
    
    # 按优先级尝试不同的编辑器
    if command -v cursor >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 使用 Cursor 编辑器打开配置文件${NC}"
        cursor "$CONFIG_FILE" &
        echo -e "${YELLOW}💡 配置文件已在 Cursor 中打开，编辑完成后保存即可生效${NC}"
    elif command -v code >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 使用 VS Code 编辑器打开配置文件${NC}"
        code "$CONFIG_FILE" &
        echo -e "${YELLOW}💡 配置文件已在 VS Code 中打开，编辑完成后保存即可生效${NC}"
    elif [[ "$OSTYPE" == "darwin"* ]] && command -v open >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 使用默认编辑器打开配置文件${NC}"
        open "$CONFIG_FILE"
        echo -e "${YELLOW}💡 配置文件已用系统默认编辑器打开${NC}"
    elif command -v vim >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 使用 vim 编辑器打开配置文件${NC}"
        vim "$CONFIG_FILE"
    elif command -v nano >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 使用 nano 编辑器打开配置文件${NC}"
        nano "$CONFIG_FILE"
    else
        echo -e "${RED}❌ 未找到可用的编辑器${NC}"
        echo -e "${YELLOW}请手动编辑配置文件: $CONFIG_FILE${NC}"
        echo -e "${YELLOW}或安装以下编辑器之一: cursor, code, vim, nano${NC}"
        return 1
    fi
}

# 交互式添加配置
interactive_add_config() {
    echo -e "${BLUE}🚀 交互式配置向导${NC}"
    echo -e "${YELLOW}正在引导您添加新的API配置...${NC}"
    echo ""

    # 选择提供商
    echo -e "${BLUE}1. 选择API提供商:${NC}"
    echo "1) Deepseek (推荐)"
    echo "2) KIMI2 (月之暗面)"
    echo "3) GLM4.5 (智谱清言)"
    echo "4) Qwen (通义千问)"
    echo "5) LongCat (美团)"
    echo "6) Claude API"
    echo "7) 退出"
    echo ""

    while true; do
        read -p "请选择提供商 (1-7): " provider_choice
        case $provider_choice in
            1) PROVIDER="DEEPSEEK"; PROVIDER_NAME="Deepseek"; break;;
            2) PROVIDER="KIMI"; PROVIDER_NAME="KIMI2"; break;;
            3) PROVIDER="GLM"; PROVIDER_NAME="GLM4.5"; break;;
            4) PROVIDER="QWEN"; PROVIDER_NAME="Qwen"; break;;
            5) PROVIDER="LONGCAT"; PROVIDER_NAME="LongCat"; break;;
            6) PROVIDER="CLAUDE"; PROVIDER_NAME="Claude API"; break;;
            7) echo -e "${YELLOW}配置已取消${NC}"; return 0;;
            *) echo -e "${RED}无效选择，请输入1-7${NC}";;
        esac
    done

    echo -e "${GREEN}✅ 已选择: $PROVIDER_NAME${NC}"
    echo ""

    # 输入API密钥
    echo -e "${BLUE}2. 配置API密钥:${NC}"
    echo -e "${YELLOW}提示: 可以配置多个密钥用于负载均衡${NC}"

    declare -a API_KEYS=()
    local key_count=1

    while true; do
        read -s -p "请输入第${key_count}个API密钥 (留空完成): " api_key
        echo ""

        if [[ -z "$api_key" ]]; then
            if [[ ${#API_KEYS[@]} -eq 0 ]]; then
                echo -e "${RED}❌ 至少需要配置一个API密钥${NC}"
                continue
            else
                break
            fi
        fi

        # 简单验证API密钥格式
        if [[ "$PROVIDER" == "DEEPSEEK" ]] && [[ ! "$api_key" =~ ^sk-.+ ]]; then
            echo -e "${YELLOW}⚠️  Deepseek API密钥通常以 'sk-' 开头${NC}"
        elif [[ "$PROVIDER" == "CLAUDE" ]] && [[ ! "$api_key" =~ ^sk-.+ ]]; then
            echo -e "${YELLOW}⚠️  Claude API密钥通常以 'sk-' 开头${NC}"
        fi

        API_KEYS+=("$api_key")
        echo -e "${GREEN}✅ 已添加第${key_count}个密钥${NC}"
        ((key_count++))

        if [[ $key_count -gt 5 ]]; then
            echo -e "${YELLOW}⚠️  已添加5个密钥，建议完成配置${NC}"
            read -p "是否继续添加? (y/N): " continue_add
            if [[ ! "$continue_add" =~ ^[Yy] ]]; then
                break
            fi
        fi
    done

    echo -e "${GREEN}✅ 共配置了 ${#API_KEYS[@]} 个API密钥${NC}"
    echo ""

    # 选择轮换策略（如果有多个密钥）
    local rotation_strategy="round_robin"
    if [[ ${#API_KEYS[@]} -gt 1 ]]; then
        echo -e "${BLUE}3. 选择密钥轮换策略:${NC}"
        echo "1) round_robin - 轮询使用 (推荐)"
        echo "2) load_balance - 负载均衡"
        echo "3) smart - 智能选择"
        echo ""

        while true; do
            read -p "请选择策略 (1-3, 默认1): " strategy_choice
            case ${strategy_choice:-1} in
                1) rotation_strategy="round_robin"; break;;
                2) rotation_strategy="load_balance"; break;;
                3) rotation_strategy="smart"; break;;
                *) echo -e "${RED}无效选择，请输入1-3${NC}";;
            esac
        done

        echo -e "${GREEN}✅ 已选择策略: $rotation_strategy${NC}"
        echo ""
    fi

    # 特殊配置项
    local base_url=""
    if [[ "$PROVIDER" == "CLAUDE" ]]; then
        echo -e "${BLUE}4. Claude API配置:${NC}"
        read -p "请输入Base URL (留空使用默认): " base_url
        if [[ -z "$base_url" ]]; then
            base_url="https://api.aicodemirror.com/api/claudecode"
        fi
        echo -e "${GREEN}✅ Base URL: $base_url${NC}"
        echo ""
    elif [[ "$PROVIDER" == "QWEN" ]]; then
        echo -e "${BLUE}4. Qwen API配置:${NC}"
        read -p "请输入Anthropic兼容端点URL (留空跳过): " base_url
        if [[ -n "$base_url" ]]; then
            echo -e "${GREEN}✅ Anthropic兼容端点: $base_url${NC}"
        fi
        echo ""
    fi

    # 显示配置摘要
    echo -e "${BLUE}📋 配置摘要:${NC}"
    echo -e "${YELLOW}提供商:${NC} $PROVIDER_NAME"
    echo -e "${YELLOW}密钥数量:${NC} ${#API_KEYS[@]}"
    if [[ ${#API_KEYS[@]} -gt 1 ]]; then
        echo -e "${YELLOW}轮换策略:${NC} $rotation_strategy"
    fi
    if [[ -n "$base_url" ]]; then
        echo -e "${YELLOW}Base URL:${NC} $base_url"
    fi
    echo ""

    # 确认保存
    read -p "确认保存配置? (Y/n): " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo -e "${YELLOW}配置已取消${NC}"
        return 0
    fi

    # 备份原配置
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${GREEN}✅ 已备份原配置文件${NC}"
    fi

    # 确保配置文件存在
    if [[ ! -f "$CONFIG_FILE" ]]; then
        create_default_config
    fi

    # 构建要添加的配置行
    local config_lines=()

    # 添加单个密钥配置（向后兼容）
    config_lines+=("")
    config_lines+=("# $PROVIDER_NAME 配置 ($(date '+%Y-%m-%d %H:%M:%S') 添加)")
    config_lines+=("${PROVIDER}_API_KEY=${API_KEYS[0]}")

    # 添加多密钥数组配置
    if [[ ${#API_KEYS[@]} -gt 1 ]]; then
        local keys_array="${PROVIDER}_API_KEYS=("
        for key in "${API_KEYS[@]}"; do
            keys_array+="$key "
        done
        keys_array+=")"
        config_lines+=("$keys_array")
        config_lines+=("${PROVIDER}_ROTATION_STRATEGY=$rotation_strategy")
    fi

    # 添加特殊配置
    if [[ "$PROVIDER" == "CLAUDE" && -n "$base_url" ]]; then
        config_lines+=("CLAUDE_BASE_URL=$base_url")
    elif [[ "$PROVIDER" == "QWEN" && -n "$base_url" ]]; then
        config_lines+=("QWEN_ANTHROPIC_BASE_URL=$base_url")
    fi

    # 写入配置文件
    for line in "${config_lines[@]}"; do
        echo "$line" >> "$CONFIG_FILE"
    done

    echo ""
    echo -e "${GREEN}🎉 配置添加成功!${NC}"
    echo -e "${YELLOW}💡 使用方法:${NC}"
    case $PROVIDER in
        "DEEPSEEK") echo -e "${BLUE}  eval \"\$(./ccs.sh deepseek)\"${NC}";;
        "KIMI") echo -e "${BLUE}  eval \"\$(./ccs.sh kimi)\"${NC}";;
        "GLM") echo -e "${BLUE}  eval \"\$(./ccs.sh glm)\"${NC}";;
        "QWEN") echo -e "${BLUE}  eval \"\$(./ccs.sh qwen)\"${NC}";;
        "LONGCAT") echo -e "${BLUE}  eval \"\$(./ccs.sh longcat)\"${NC}";;
        "CLAUDE") echo -e "${BLUE}  eval \"\$(./ccs.sh claude)\"${NC}";;
    esac
    echo -e "${YELLOW}💡 查看状态:${NC} ${BLUE}./ccs.sh status${NC}"

    # 询问是否立即切换
    echo ""
    read -p "是否立即切换到新配置? (y/N): " switch_now
    if [[ "$switch_now" =~ ^[Yy] ]]; then
        case $PROVIDER in
            "DEEPSEEK") eval "$(emit_env_exports deepseek)" && echo -e "${GREEN}✅ 已切换到Deepseek${NC}";;
            "KIMI") eval "$(emit_env_exports kimi)" && echo -e "${GREEN}✅ 已切换到KIMI2${NC}";;
            "GLM") eval "$(emit_env_exports glm)" && echo -e "${GREEN}✅ 已切换到GLM4.5${NC}";;
            "QWEN") eval "$(emit_env_exports qwen)" && echo -e "${GREEN}✅ 已切换到Qwen${NC}";;
            "LONGCAT") eval "$(emit_env_exports longcat)" && echo -e "${GREEN}✅ 已切换到LongCat${NC}";;
            "CLAUDE") eval "$(emit_env_exports claude)" && echo -e "${GREEN}✅ 已切换到Claude API${NC}";;
        esac
    fi
}

# 仅输出 export 语句的环境设置（用于 eval）
emit_env_exports() {
    local target="$1"
    # 加载配置以便进行存在性判断（环境变量优先，不打印密钥）
    load_config || return 1

    # 通用前导：清理旧变量
    local prelude="unset ANTHROPIC_BASE_URL ANTHROPIC_API_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY ANTHROPIC_MODEL ANTHROPIC_SMALL_FAST_MODEL API_TIMEOUT_MS CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"

    case "$target" in
        "deepseek"|"ds")
            # 尝试使用多 key 选择功能
            local strategy="${DEEPSEEK_ROTATION_STRATEGY:-round_robin}"
            local selected_key
            selected_key=$(select_best_key "DEEPSEEK" "$strategy")

            if [[ -n "$selected_key" ]]; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.deepseek.com/anthropic'"
                echo "export ANTHROPIC_API_URL='https://api.deepseek.com/anthropic'"
                echo "export ANTHROPIC_AUTH_TOKEN='$selected_key'"
                local ds_model="${DEEPSEEK_MODEL:-deepseek-chat}"
                local ds_small="${DEEPSEEK_SMALL_FAST_MODEL:-deepseek-chat}"
                echo "export ANTHROPIC_MODEL='${ds_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${ds_small}'"

                # 记录使用情况
                record_key_usage "DEEPSEEK" "$selected_key" "true" >/dev/null 2>&1 &
            elif is_effectively_set "$PPINFRA_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.ppinfra.com/openai/v1/anthropic'"
                echo "export ANTHROPIC_API_URL='https://api.ppinfra.com/openai/v1/anthropic'"
                echo "export ANTHROPIC_AUTH_TOKEN='$PPINFRA_API_KEY'"
                local ds_model="${DEEPSEEK_MODEL:-deepseek/deepseek-v3.1}"
                local ds_small="${DEEPSEEK_SMALL_FAST_MODEL:-deepseek/deepseek-v3.1}"
                echo "export ANTHROPIC_MODEL='${ds_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${ds_small}'"
            else
                echo "# ❌ 未检测到 DEEPSEEK_API_KEY/DEEPSEEK_API_KEYS 或 PPINFRA_API_KEY" 1>&2
                return 1
            fi
            ;;
        "kimi"|"kimi2")
            # 获取切换策略
            local strategy="${KIMI_ROTATION_STRATEGY:-round_robin}"

            # 尝试从多 key 中选择最佳 key
            local selected_key
            selected_key=$(select_best_key "KIMI" "$strategy")

            if [[ -n "$selected_key" ]]; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.moonshot.cn/anthropic'"
                echo "export ANTHROPIC_API_URL='https://api.moonshot.cn/anthropic'"
                echo "export ANTHROPIC_AUTH_TOKEN='$selected_key'"
                local kimi_model="${KIMI_MODEL:-kimi-k2-0905-preview}"
                local kimi_small="${KIMI_SMALL_FAST_MODEL:-kimi-k2-0905-preview}"
                echo "export ANTHROPIC_MODEL='${kimi_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${kimi_small}'"

                # 记录使用情况
                record_key_usage "KIMI" "$selected_key" "true" >/dev/null 2>&1 &
            elif is_effectively_set "$PPINFRA_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.ppinfra.com/openai/v1/anthropic'"
                echo "export ANTHROPIC_API_URL='https://api.ppinfra.com/openai/v1/anthropic'"
                echo "if [ -z \"\${PPINFRA_API_KEY}\" ] && [ -f \"\$HOME/.ccs_config\" ]; then . \"\$HOME/.ccs_config\" >/dev/null 2>&1; fi"
                echo "export ANTHROPIC_AUTH_TOKEN=\"\${PPINFRA_API_KEY}\""
local kimi_model="${KIMI_MODEL:-kimi-k2-0905-preview}"
                local kimi_small="${KIMI_SMALL_FAST_MODEL:-kimi-k2-0905-preview}"
                echo "export ANTHROPIC_MODEL='${kimi_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${kimi_small}'"
            else
                echo "# ❌ 未检测到 KIMI_API_KEY 或 PPINFRA_API_KEY" 1>&2
                return 1
            fi
            ;;
        "qwen")
            # 获取切换策略
            local strategy="${QWEN_ROTATION_STRATEGY:-round_robin}"

            # 尝试从多 key 中选择最佳 key
            local selected_key
            selected_key=$(select_best_key "QWEN" "$strategy")

            if [[ -n "$selected_key" && -n "$QWEN_ANTHROPIC_BASE_URL" ]]; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='${QWEN_ANTHROPIC_BASE_URL}'"
                echo "export ANTHROPIC_API_URL='${QWEN_ANTHROPIC_BASE_URL}'"
                echo "export ANTHROPIC_AUTH_TOKEN='$selected_key'"
                local qwen_model="${QWEN_MODEL:-qwen3-next-80b-a3b-thinking}"
                local qwen_small="${QWEN_SMALL_FAST_MODEL:-qwen3-next-80b-a3b-thinking}"
                echo "export ANTHROPIC_MODEL='${qwen_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${qwen_small}'"

                # 记录使用情况
                record_key_usage "QWEN" "$selected_key" "true" >/dev/null 2>&1 &
            elif is_effectively_set "$PPINFRA_API_KEY"; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.ppinfra.com/openai/v1/anthropic'"
                echo "export ANTHROPIC_API_URL='https://api.ppinfra.com/openai/v1/anthropic'"
                echo "if [ -z \"\${PPINFRA_API_KEY}\" ] && [ -f \"\$HOME/.ccs_config\" ]; then . \"\$HOME/.ccs_config\" >/dev/null 2>&1; fi"
                echo "export ANTHROPIC_AUTH_TOKEN=\"\${PPINFRA_API_KEY}\""
                local qwen_model="${QWEN_MODEL:-qwen3-next-80b-a3b-thinking}"
                local qwen_small="${QWEN_SMALL_FAST_MODEL:-qwen3-next-80b-a3b-thinking}"
                echo "export ANTHROPIC_MODEL='${qwen_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${qwen_small}'"
            else
                echo "# ❌ 未检测到 QWEN_API_KEY / QWEN_ANTHROPIC_BASE_URL 或 PPINFRA_API_KEY" 1>&2
                return 1
            fi
            ;;
        "glm"|"glm4"|"glm4.5")
            # 获取切换策略
            local strategy="${GLM_ROTATION_STRATEGY:-round_robin}"

            # 尝试从多 key 中选择最佳 key
            local selected_key
            selected_key=$(select_best_key "GLM" "$strategy")

            if [[ -n "$selected_key" ]]; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://open.bigmodel.cn/api/anthropic'"
                echo "export ANTHROPIC_API_URL='https://open.bigmodel.cn/api/anthropic'"
                echo "export ANTHROPIC_AUTH_TOKEN='$selected_key'"
                local glm_model="${GLM_MODEL:-glm-4.5}"
                local glm_small="${GLM_SMALL_FAST_MODEL:-glm-4.5-air}"
                echo "export ANTHROPIC_MODEL='${glm_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${glm_small}'"

                # 记录使用情况
                record_key_usage "GLM" "$selected_key" "true" >/dev/null 2>&1 &
            else
                echo "# ❌ GLM 仅支持官方密钥，请设置 GLM_API_KEY 或 GLM_API_KEYS" 1>&2
                return 1
            fi
            ;;
        "claude"|"sonnet"|"s")
            # 获取切换策略
            local strategy="${CLAUDE_ROTATION_STRATEGY:-round_robin}"

            # 检查是否配置了自定义API设置
            if [[ -n "$CLAUDE_BASE_URL" ]]; then
                # API模式：使用自定义BASE_URL和密钥
                local selected_key
                selected_key=$(select_best_key "CLAUDE" "$strategy")

                if [[ -n "$selected_key" ]]; then
                    echo "$prelude"
                    echo "export API_TIMEOUT_MS='600000'"
                    echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                    echo "export ANTHROPIC_BASE_URL='$CLAUDE_BASE_URL'"
                    echo "export ANTHROPIC_API_URL='$CLAUDE_BASE_URL'"
                    echo "export ANTHROPIC_API_KEY='$selected_key'"
                    echo "export ANTHROPIC_AUTH_TOKEN=''"
                    local claude_model="${CLAUDE_MODEL:-claude-sonnet-4-20250514}"
                    local claude_small="${CLAUDE_SMALL_FAST_MODEL:-claude-sonnet-4-20250514}"
                    echo "export ANTHROPIC_MODEL='${claude_model}'"
                    echo "export ANTHROPIC_SMALL_FAST_MODEL='${claude_small}'"

                    # 记录使用情况
                    record_key_usage "CLAUDE" "$selected_key" "true" >/dev/null 2>&1 &
                else
                    echo "# ❌ 配置了 CLAUDE_BASE_URL 但未找到可用的 API 密钥" 1>&2
                    return 1
                fi
            else
                # Pro模式：使用Claude Pro订阅（原有逻辑）
                echo "$prelude"
                echo "unset ANTHROPIC_BASE_URL"
                echo "unset ANTHROPIC_API_URL"
                echo "unset ANTHROPIC_API_KEY"
                echo "unset ANTHROPIC_AUTH_TOKEN"
                local claude_model="${CLAUDE_MODEL:-claude-sonnet-4-20250514}"
                local claude_small="${CLAUDE_SMALL_FAST_MODEL:-claude-sonnet-4-20250514}"
                echo "export ANTHROPIC_MODEL='${claude_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${claude_small}'"
            fi
            ;;
        "opus"|"o")
            # 获取切换策略
            local strategy="${OPUS_ROTATION_STRATEGY:-round_robin}"

            # 检查是否配置了自定义API设置
            if [[ -n "$OPUS_BASE_URL" ]]; then
                # API模式：使用自定义BASE_URL和密钥
                local selected_key
                selected_key=$(select_best_key "OPUS" "$strategy")

                if [[ -n "$selected_key" ]]; then
                    echo "$prelude"
                    echo "export API_TIMEOUT_MS='600000'"
                    echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                    echo "export ANTHROPIC_BASE_URL='$OPUS_BASE_URL'"
                    echo "export ANTHROPIC_API_URL='$OPUS_BASE_URL'"
                    echo "export ANTHROPIC_API_KEY='$selected_key'"
                    echo "export ANTHROPIC_AUTH_TOKEN=''"
                    local opus_model="${OPUS_MODEL:-claude-opus-4-1-20250805}"
                    local opus_small="${OPUS_SMALL_FAST_MODEL:-claude-sonnet-4-20250514}"
                    echo "export ANTHROPIC_MODEL='${opus_model}'"
                    echo "export ANTHROPIC_SMALL_FAST_MODEL='${opus_small}'"

                    # 记录使用情况
                    record_key_usage "OPUS" "$selected_key" "true" >/dev/null 2>&1 &
                else
                    echo "# ❌ 配置了 OPUS_BASE_URL 但未找到可用的 API 密钥" 1>&2
                    return 1
                fi
            else
                # Pro模式：使用Claude Pro订阅（原有逻辑）
                echo "$prelude"
                echo "unset ANTHROPIC_BASE_URL"
                echo "unset ANTHROPIC_API_URL"
                echo "unset ANTHROPIC_API_KEY"

                # 尝试从多 key 中选择最佳 key（可选，如果用户有API密钥）
                local selected_key
                selected_key=$(select_best_key "OPUS" "$strategy")

                # 如果有API密钥，则设置；否则使用Claude Pro订阅
                if [[ -n "$selected_key" ]]; then
                    echo "export ANTHROPIC_AUTH_TOKEN='$selected_key'"
                    # 记录使用情况
                    record_key_usage "OPUS" "$selected_key" "true" >/dev/null 2>&1 &
                else
                    echo "unset ANTHROPIC_AUTH_TOKEN"
                fi

                local opus_model="${OPUS_MODEL:-claude-opus-4-1-20250805}"
                local opus_small="${OPUS_SMALL_FAST_MODEL:-claude-sonnet-4-20250514}"
                echo "export ANTHROPIC_MODEL='${opus_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${opus_small}'"
            fi
            ;;
        "longcat")
            # 获取切换策略
            local strategy="${LONGCAT_ROTATION_STRATEGY:-round_robin}"

            # 尝试从多 key 中选择最佳 key
            local selected_key
            selected_key=$(select_best_key "LONGCAT" "$strategy")

            if [[ -n "$selected_key" ]]; then
                echo "$prelude"
                echo "export API_TIMEOUT_MS='600000'"
                echo "export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC='1'"
                echo "export ANTHROPIC_BASE_URL='https://api.longcat.chat/anthropic'"
                echo "export ANTHROPIC_API_URL='https://api.longcat.chat/anthropic'"
                echo "export ANTHROPIC_AUTH_TOKEN='$selected_key'"
                local lc_model="${LONGCAT_MODEL:-LongCat-Flash-Thinking}"
                local lc_small="${LONGCAT_SMALL_FAST_MODEL:-LongCat-Flash-Chat}"
                echo "export ANTHROPIC_MODEL='${lc_model}'"
                echo "export ANTHROPIC_SMALL_FAST_MODEL='${lc_small}'"

                # 记录使用情况
                record_key_usage "LONGCAT" "$selected_key" "true" >/dev/null 2>&1 &
            else
                echo "# ❌ 未检测到 LONGCAT_API_KEY 或 LONGCAT_API_KEYS" 1>&2
                return 1
            fi
            ;;
        *)
            echo "# 用法: $(basename "$0") env [deepseek|kimi|qwen|glm|claude|opus]" 1>&2
            return 1
            ;;
    esac
}


# 主函数
main() {
    # 加载配置（环境变量优先）
    if ! load_config; then
        return 1
    fi

    # 处理参数
    case "${1:-help}" in
        "deepseek"|"ds")
            emit_env_exports deepseek
            ;;
        "kimi"|"kimi2")
            emit_env_exports kimi
            ;;
        "qwen")
            emit_env_exports qwen
            ;;
        "longcat"|"lc")
            emit_env_exports longcat
            ;;
        "glm"|"glm4"|"glm4.5")
            emit_env_exports glm
            ;;
        "claude"|"sonnet"|"s")
            emit_env_exports claude
            ;;
        "opus"|"o")
            emit_env_exports opus
            ;;
        "env")
            shift
            emit_env_exports "${1:-}"
            ;;
        "status"|"st")
            if [[ "$2" == "--detailed" ]]; then
                show_detailed_status
            else
                show_status
            fi
            ;;
        "stats")
            show_usage_stats
            ;;
        "rotate")
            shift
            rotate_key "$1"
            ;;
        "test-keys")
            shift
            test_keys "$1"
            ;;
        "config"|"cfg")
            edit_config
            ;;
        "help"|"h"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知选项: $1${NC}"
            echo ""
            show_help
            return 1
            ;;
    esac
}

# 执行主函数
main "$@"
