#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

# Configuration - Update these with your actual values
USER_POOL_ID="us-east-1_malguUP4s"
CLIENT_ID="6aosqe6tgct0m8fasnfvpur4cc"
API_ENDPOINT="https://496ja981q2.execute-api.us-east-1.amazonaws.com/dev"
USERNAME="test@example.com"
PASSWORD="Test123!"

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to print results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2 - Status Code: $3${NC}"
    fi
}

# Get authentication tokens
get_auth_tokens() {
    print_header "Getting Authentication Tokens"
    
    AUTH_RESULT=$(aws cognito-idp admin-initiate-auth \
        --user-pool-id $USER_POOL_ID \
        --client-id $CLIENT_ID \
        --auth-flow ADMIN_USER_PASSWORD_AUTH \
        --auth-parameters USERNAME=$USERNAME,PASSWORD=$PASSWORD)
    
    ID_TOKEN=$(echo $AUTH_RESULT | jq -r '.AuthenticationResult.IdToken')
    
    if [ -z "$ID_TOKEN" ] || [ "$ID_TOKEN" = "null" ]; then
        print_result 1 "Failed to get ID token"
        exit 1
    fi
    
    print_result $? "Token retrieval"
    echo "ID Token: $ID_TOKEN"
    echo -e "\nCopy this token for Postman in the Authorization header as: Bearer <token>"
}

# Test rate limit
test_rate_limit() {
    print_header "Testing Rate Limit (10 requests per minute)"
    
    echo "Making 15 rapid requests to test rate limiting..."
    
    for i in {1..15}; do
        echo -e "\nRequest $i:"
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$API_ENDPOINT/todos" \
            -H "Authorization: Bearer $ID_TOKEN")
        
        if [ "$RESPONSE" -eq 200 ]; then
            print_result 0 "Request successful"
        elif [ "$RESPONSE" -eq 403 ]; then
            print_result 1 "Request blocked by WAF rate limit" $RESPONSE
        else
            print_result 1 "Request failed with unexpected error" $RESPONSE
        fi
        
        # Small delay to make output readable
        sleep 0.5
    done
}

# Main execution
main() {
    print_header "Rate Limit Testing"
    
    get_auth_tokens
    test_rate_limit
    
    print_header "Testing Complete"
    echo -e "\nPostman Instructions:"
    echo "1. Create a new request to: $API_ENDPOINT/todos"
    echo "2. Set Authorization header: Bearer <token> (use the ID Token from above)"
    echo "3. Send request multiple times rapidly to trigger rate limiting"
    echo "4. After around 10 requests in a minute, you should see 403 responses"
}

# Run the script
main 