#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

# Configuration
USER_POOL_ID="us-east-1_eHXvjQ9OC"
CLIENT_ID="7679ue4du5uibe723p0mj3thn6"
API_ENDPOINT="https://ambv3y442f.execute-api.us-east-1.amazonaws.com/dev"
USERNAME="test@example.com"
PASSWORD="Test123!"
TODOS_TABLE="dev-todos"
NOTES_TABLE="dev-notes"

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
}

# Clean up todos
cleanup_todos() {
    print_header "Cleaning up Todos"
    
    # Get all todos
    TODOS=$(curl -s -X GET "$API_ENDPOINT/todos" \
        -H "Authorization: Bearer $ID_TOKEN" | jq -r '.[].id')
    
    # Delete each todo
    for TODO_ID in $TODOS; do
        echo "Deleting todo: $TODO_ID"
        curl -s -X DELETE "$API_ENDPOINT/todos/$TODO_ID" \
            -H "Authorization: Bearer $ID_TOKEN"
    done
    
    print_result $? "Todos cleanup"
}

# Clean up notes
cleanup_notes() {
    print_header "Cleaning up Notes"
    
    # Get all notes
    NOTES=$(curl -s -X GET "$API_ENDPOINT/notes" \
        -H "Authorization: Bearer $ID_TOKEN" | jq -r '.[].id')
    
    # Delete each note
    for NOTE_ID in $NOTES; do
        echo "Deleting note: $NOTE_ID"
        curl -s -X DELETE "$API_ENDPOINT/notes/$NOTE_ID" \
            -H "Authorization: Bearer $ID_TOKEN"
    done
    
    print_result $? "Notes cleanup"
}

# Delete test user
delete_test_user() {
    print_header "Deleting Test User"
    
    # Delete user from Cognito
    aws cognito-idp admin-delete-user \
        --user-pool-id $USER_POOL_ID \
        --username $USERNAME
    
    print_result $? "User deletion"
}

# Verify cleanup
verify_cleanup() {
    print_header "Verifying Cleanup"
    
    # Check todos
    TODOS_COUNT=$(curl -s -X GET "$API_ENDPOINT/todos" \
        -H "Authorization: Bearer $ID_TOKEN" | jq '. | length')
    
    if [ "$TODOS_COUNT" -eq 0 ]; then
        print_result 0 "Todos table is empty"
    else
        print_result 1 "Todos table still has items"
    fi
    
    # Check notes
    NOTES_COUNT=$(curl -s -X GET "$API_ENDPOINT/notes" \
        -H "Authorization: Bearer $ID_TOKEN" | jq '. | length')
    
    if [ "$NOTES_COUNT" -eq 0 ]; then
        print_result 0 "Notes table is empty"
    else
        print_result 1 "Notes table still has items"
    fi
}

# Main execution
main() {
    print_header "Starting Cleanup"
    
    # Check if configuration is provided
    if [ -z "$USER_POOL_ID" ] || [ -z "$CLIENT_ID" ] || [ -z "$API_ENDPOINT" ]; then
        echo -e "${RED}Please set USER_POOL_ID, CLIENT_ID, and API_ENDPOINT variables${NC}"
        exit 1
    fi
    
    get_auth_tokens
    cleanup_todos
    cleanup_notes
    delete_test_user
    verify_cleanup
    
    print_header "Cleanup Complete"
}

# Run the script
main 