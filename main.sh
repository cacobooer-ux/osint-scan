#!/usr/bin/env bash
# osint-scan – Unified OSINT Tool (rep + breach + find)
# Usage: ./osint-scan target@email.com

TARGET="$1"
OUTPUT_DIR="osint_results"
mkdir -p "$OUTPUT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ -z "$TARGET" ]; then
    echo -e "${RED}Usage: $0 <email>${NC}"
    exit 1
fi

echo -e "${GREEN}[+] OSINT-FUSION-LITE starting for: $TARGET${NC}"
echo -e "${YELLOW}[+] Engines: rep | breach | find${NC}\n"

# ============================================================
# 1. rep – Email Reputation (Igonrant)
# ============================================================
echo -e "${GREEN}[1] rep – Scanning reputation...${NC}"
rep_result=$(curl -s -X GET "https://api.igonrant.com/v1/reputation?email=$TARGET" \
    -H "User-Agent: OSINT-FUSION/2099" 2>/dev/null || echo '{"error":"fallback"}')
echo "$rep_result" | jq '.' > "$OUTPUT_DIR/${TARGET}_rep.json" 2>/dev/null
echo -e "${GREEN}    ✔ Saved to: $OUTPUT_DIR/${TARGET}_rep.json${NC}"

# ============================================================
# 2. breach – Data Breach Search (Tutitus / HIBP)
# ============================================================
echo -e "\n${GREEN}[2] breach – Searching breaches...${NC}"
breach_result=$(curl -s -X GET "https://haveibeenpwned.com/api/v3/breachedaccount/$TARGET" \
    -H "hibp-api-key: YOUR_API_KEY" 2>/dev/null || echo '[]')
echo "$breach_result" | jq '.' > "$OUTPUT_DIR/${TARGET}_breach.json" 2>/dev/null
if [ "$breach_result" == "[]" ]; then
    echo -e "${YELLOW}    ✔ No breaches found${NC}"
else
    count=$(echo "$breach_result" | jq 'length' 2>/dev/null)
    echo -e "${GREEN}    ✔ $count breaches found → saved${NC}"
fi

# ============================================================
# 3. find – Account Existence (Holehe)
# ============================================================
echo -e "\n${GREEN}[3] find – Checking accounts on 100+ services...${NC}"
find_result=$(holehe "$TARGET" --no-color --only-used 2>/dev/null || echo "fallback")
echo "$find_result" > "$OUTPUT_DIR/${TARGET}_find.txt"
echo -e "${GREEN}    ✔ Saved to: $OUTPUT_DIR/${TARGET}_find.txt${NC}"

# ============================================================
# Summary
# ============================================================
echo -e "\n${GREEN}[+] ========== SUMMARY ==========${NC}"
echo -e "Target: $TARGET"
echo -e "Results saved in: $OUTPUT_DIR/"
echo -e "  - rep.json   (reputation score)"
echo -e "  - breach.json (breach history)"
echo -e "  - find.txt   (accounts found)"

# Show quick stats
if command -v jq &> /dev/null; then
    spam=$(jq -r '.spam_score // "N/A"' "$OUTPUT_DIR/${TARGET}_rep.json" 2>/dev/null)
    echo -e "\n${YELLOW}Quick Stats:${NC}"
    echo -e "  Spam Score: $spam"
    breach_count=$(jq 'length' "$OUTPUT_DIR/${TARGET}_breach.json" 2>/dev/null)
    echo -e "  Breaches: $breach_count"
fi

echo -e "\n${GREEN}[+] Done.${NC}"
