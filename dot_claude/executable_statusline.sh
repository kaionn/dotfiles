#!/bin/bash
# Claude Code Token 消費量表示

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size')
TOTAL_INPUT=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
TOTAL_OUTPUT=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# コンテキスト使用量を計算
USAGE=$(echo "$input" | jq '.context_window.current_usage')
if [ "$USAGE" != "null" ]; then
    INPUT_TOKENS=$(echo "$USAGE" | jq '.input_tokens // 0')
    OUTPUT_TOKENS=$(echo "$USAGE" | jq '.output_tokens // 0')
    CACHE_CREATION=$(echo "$USAGE" | jq '.cache_creation_input_tokens // 0')
    CACHE_READ=$(echo "$USAGE" | jq '.cache_read_input_tokens // 0')

    CURRENT=$((INPUT_TOKENS + OUTPUT_TOKENS + CACHE_CREATION + CACHE_READ))
    REMAINING=$((CONTEXT_SIZE - CURRENT))
    PERCENT=$((CURRENT * 100 / CONTEXT_SIZE))
else
    CURRENT=0
    REMAINING=$CONTEXT_SIZE
    PERCENT=0
fi

# 数値を読みやすく整形 (1000 -> 1K, 1000000 -> 1M)
format_number() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        printf "%.1fM" "$(echo "scale=1; $num / 1000000" | bc)"
    elif [ "$num" -ge 1000 ]; then
        printf "%.1fK" "$(echo "scale=1; $num / 1000" | bc)"
    else
        printf "%d" "$num"
    fi
}

REMAINING_FMT=$(format_number $REMAINING)
TOTAL_IN_FMT=$(format_number $TOTAL_INPUT)
TOTAL_OUT_FMT=$(format_number $TOTAL_OUTPUT)

# 表示フォーマット
printf "[%s] ⚡ In: %s Out: %s | 残り: %s (%d%%) | $%.4f" \
    "$MODEL" "$TOTAL_IN_FMT" "$TOTAL_OUT_FMT" "$REMAINING_FMT" "$((100 - PERCENT))" "$COST"
