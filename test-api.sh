#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

# Configuration
USER_POOL_ID="us-east-1_malguUP4s"
CLIENT_ID="6aosqe6tgct0m8fasnfvpur4cc"
API_ENDPOINT="https://496ja981q2.execute-api.us-east-1.amazonaws.com/dev"
USERNAME="test@example.com"
PASSWORD="Test123!"

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

# Check if required tools are installed
check_requirements() {
    print_header "Checking Requirements"
    
    command -v aws >/dev/null 2>&1 || { echo -e "${RED}AWS CLI is required but not installed.${NC}"; exit 1; }
    command -v jq >/dev/null 2>&1 || { echo -e "${RED}jq is required but not installed.${NC}"; exit 1; }
    command -v curl >/dev/null 2>&1 || { echo -e "${RED}curl is required but not installed.${NC}"; exit 1; }
    
    print_result 0 "All requirements met"
}

# Register a new user
register_user() {
    print_header "Registering User"
    
    # Try to sign up, ignore if user exists
    aws cognito-idp sign-up \
        --client-id $CLIENT_ID \
        --username $USERNAME \
        --password $PASSWORD \
        --user-attributes Name=email,Value=$USERNAME Name=name,Value=TestUser \
        2>/dev/null || true
    
    print_result $? "User registration"
    
    # Try to confirm user, ignore if already confirmed
    aws cognito-idp admin-confirm-sign-up \
        --user-pool-id $USER_POOL_ID \
        --username $USERNAME \
        2>/dev/null || true
    
    print_result $? "User confirmation"
}

# Get authentication tokens
get_auth_tokens() {
    print_header "Getting Authentication Tokens"
    
    AUTH_RESULT=$(aws cognito-idp admin-initiate-auth \
        --user-pool-id $USER_POOL_ID \
        --client-id $CLIENT_ID \
        --auth-flow ADMIN_USER_PASSWORD_AUTH \
        --auth-parameters USERNAME=$USERNAME,PASSWORD=$PASSWORD)
    
    ACCESS_TOKEN=$(echo $AUTH_RESULT | jq -r '.AuthenticationResult.AccessToken')
    ID_TOKEN=$(echo $AUTH_RESULT | jq -r '.AuthenticationResult.IdToken')
    REFRESH_TOKEN=$(echo $AUTH_RESULT | jq -r '.AuthenticationResult.RefreshToken')
    
    if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" = "null" ]; then
        print_result 1 "Failed to get access token"
        exit 1
    fi
    
    print_result $? "Token retrieval"
}

# Test Todos API
test_todos_api() {
    print_header "Testing Todos API"
    
    # Create a todo
    echo "Creating a todo..."
    CREATE_TODO_RESPONSE=$(curl -s -X POST "$API_ENDPOINT/todos" \
        -H "Authorization: Bearer $ID_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"title": "Test Todo"}')
    
    TODO_ID=$(echo $CREATE_TODO_RESPONSE | jq -r '.id')
    print_result $? "Create todo"
    
    # Get all todos
    echo "Getting all todos..."
    curl -s -X GET "$API_ENDPOINT/todos" \
        -H "Authorization: Bearer $ID_TOKEN" | jq
    print_result $? "Get all todos"
    
    # Get specific todo
    echo "Getting specific todo..."
    curl -s -X GET "$API_ENDPOINT/todos/$TODO_ID" \
        -H "Authorization: Bearer $ID_TOKEN" | jq
    print_result $? "Get specific todo"
    
    # Update todo
    echo "Updating todo..."
    curl -s -X PUT "$API_ENDPOINT/todos/$TODO_ID" \
        -H "Authorization: Bearer $ID_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"title": "Updated Todo", "completed": true}' | jq
    print_result $? "Update todo"
    
    # Delete todo
    echo "Deleting todo..."
    curl -s -X DELETE "$API_ENDPOINT/todos/$TODO_ID" \
        -H "Authorization: Bearer $ID_TOKEN"
    print_result $? "Delete todo"
}

# Test Notes API
test_notes_api() {
    print_header "Testing Notes API"
    
    # Create a note
    echo "Creating a note..."
    CREATE_NOTE_RESPONSE=$(curl -s -X POST "$API_ENDPOINT/notes" \
        -H "Authorization: Bearer $ID_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"content": "Test Note"}')
    
    NOTE_ID=$(echo $CREATE_NOTE_RESPONSE | jq -r '.id')
    print_result $? "Create note"
    
    # Get all notes
    echo "Getting all notes..."
    curl -s -X GET "$API_ENDPOINT/notes" \
        -H "Authorization: Bearer $ID_TOKEN" | jq
    print_result $? "Get all notes"
    
    # Get specific note
    echo "Getting specific note..."
    curl -s -X GET "$API_ENDPOINT/notes/$NOTE_ID" \
        -H "Authorization: Bearer $ID_TOKEN" | jq
    print_result $? "Get specific note"
    
    # Update note
    echo "Updating note..."
    curl -s -X PUT "$API_ENDPOINT/notes/$NOTE_ID" \
        -H "Authorization: Bearer $ID_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"content": "Updated Note"}' | jq
    print_result $? "Update note"
    
    # Delete note
    echo "Deleting note..."
    curl -s -X DELETE "$API_ENDPOINT/notes/$NOTE_ID" \
        -H "Authorization: Bearer $ID_TOKEN"
    print_result $? "Delete note"
}

# Test error cases
test_error_cases() {
    print_header "Testing Error Cases"
    
    # Test without authentication
    echo "Testing without authentication..."
    curl -s -X GET "$API_ENDPOINT/todos" | jq
    print_result $? "Unauthorized access"
    
    # Test invalid todo ID
    echo "Testing invalid todo ID..."
    curl -s -X GET "$API_ENDPOINT/todos/invalid-id" \
        -H "Authorization: Bearer $ID_TOKEN" | jq
    print_result $? "Invalid ID handling"
    
    # Test invalid note ID
    echo "Testing invalid note ID..."
    curl -s -X GET "$API_ENDPOINT/notes/invalid-id" \
        -H "Authorization: Bearer $ID_TOKEN" | jq
    print_result $? "Invalid ID handling"
}

# Main execution
main() {
    print_header "Starting API Tests"
    
    # Check if configuration is provided
    if [ -z "$USER_POOL_ID" ] || [ -z "$CLIENT_ID" ] || [ -z "$API_ENDPOINT" ]; then
        echo -e "${RED}Please set USER_POOL_ID, CLIENT_ID, and API_ENDPOINT variables${NC}"
        exit 1
    fi
    
    check_requirements
    register_user
    get_auth_tokens
    test_todos_api
    test_notes_api
    test_error_cases
    
    print_header "Testing Complete"
}

# Run the script
main 