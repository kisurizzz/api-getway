#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

# Configuration
API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name secure-api-stack --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' --output text)
USER_POOL_ID="us-east-1_eHXvjQ9OC"
CLIENT_ID="7679ue4du5uibe723p0mj3thn6"
USERNAME="test@example.com"
PASSWORD="Test123!"

echo "Testing WAF with API endpoint: $API_ENDPOINT"

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to print results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

# Get authentication token
get_auth_token() {
    # This is a placeholder. In a real scenario, you would:
    # 1. Use AWS Cognito to get a token
    # 2. Store and reuse the token
    # For testing purposes, we'll use a dummy token
    echo "dummy-token"
}

# Function to make a request and print the response
make_request() {
    local method=$1
    local path=$2
    local data=$3
    local headers=$4
    
    echo -e "\nMaking $method request to $path"
    if [ -n "$data" ]; then
        curl -X $method "$API_ENDPOINT$path" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $(get_auth_token)" \
            $headers \
            -d "$data" \
            -w "\nStatus: %{http_code}\n" \
            -s
    else
        curl -X $method "$API_ENDPOINT$path" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $(get_auth_token)" \
            $headers \
            -w "\nStatus: %{http_code}\n" \
            -s
    fi
}

# Test 1: Rate Limiting
echo -e "\n=== Test 1: Rate Limiting ==="
echo "Making 10 rapid requests to test rate limiting..."
for i in {1..10}; do
    make_request "GET" "todos" "" ""
    sleep 0.1
done

# Test 2: SQL Injection Attempt
echo -e "\n=== Test 2: SQL Injection Attempt ==="
make_request "GET" "todos?query=1' OR '1'='1" "" ""

# Test 3: XSS Attempt
echo -e "\n=== Test 3: XSS Attempt ==="
make_request "POST" "todos" '{"title":"<script>alert(1)</script>"}' ""

# Test 4: Path Traversal
echo -e "\n=== Test 4: Path Traversal ==="
make_request "GET" "../../etc/passwd" "" ""

# Test 5: Large Payload
echo -e "\n=== Test 5: Large Payload ==="
LARGE_PAYLOAD=$(printf 'a%.0s' {1..10000})
make_request "POST" "todos" "{\"title\":\"$LARGE_PAYLOAD\"}" ""

# Test 6: Invalid HTTP Methods
echo -e "\n=== Test 6: Invalid HTTP Methods ==="
make_request "TRACE" "todos" "" ""
make_request "OPTIONS" "todos" "" ""

# Test 7: Malformed JSON
echo -e "\n=== Test 7: Malformed JSON ==="
make_request "POST" "todos" '{"title": "test", "completed": true' ""

# Test 8: Special Characters in Path
echo -e "\n=== Test 8: Special Characters in Path ==="
make_request "GET" "todos/../../etc/passwd" "" ""

# Test 9: Common Attack Patterns
echo -e "\n=== Test 9: Common Attack Patterns ==="
ATTACK_PATTERNS=(
    "'; DROP TABLE todos; --"
    "<script>alert('xss')</script>"
    "1' OR '1'='1"
    "../../../etc/passwd"
    "<?php system('ls'); ?>"
    "eval(base64_decode('ZWNobyAiaGVsbG8iOw=='));"
)

for pattern in "${ATTACK_PATTERNS[@]}"; do
    echo "Testing pattern: $pattern"
    make_request "POST" "todos" "{\"title\":\"$pattern\"}" ""
done

echo -e "\nWAF testing completed!"

# Main execution
main() {
    print_header "Starting WAF Tests"
    
    # Check if configuration is provided
    if [ -z "$API_ENDPOINT" ] || [ -z "$USER_POOL_ID" ] || [ -z "$CLIENT_ID" ]; then
        echo -e "${RED}Please set API_ENDPOINT, USER_POOL_ID, and CLIENT_ID variables${NC}"
        exit 1
    fi
    
    test_rate_limiting
    test_sql_injection
    test_xss
    test_ip_reputation
    
    print_header "WAF Tests Complete"
}

# Run the script
main 