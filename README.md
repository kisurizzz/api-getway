# Simple API Gateway with WAF Implementation

This project implements a secure API Gateway with WAF protection, featuring two simple APIs (Todos and Notes) with authentication and rate limiting.

## Live Demo

The frontend application is deployed and available at: [https://api-getway-nine.vercel.app/](https://api-getway-nine.vercel.app/)

## Architecture

- AWS API Gateway for API management
- AWS WAF for security
- AWS Cognito for authentication
- AWS Lambda for serverless functions
- Amazon DynamoDB for data storage

## Prerequisites

1. AWS CLI installed and configured
2. AWS SAM CLI installed
3. Node.js 18.x or later
4. An AWS account with appropriate permissions

## Installation

1. Install dependencies for Lambda functions:
```bash
cd src/todos && npm install
cd ../notes && npm install
```

2. Deploy the application:
```bash
sam build
sam deploy --guided
```

## API Endpoints

### Todos API
- GET /todos - List all todos
- GET /todos/{id} - Get a specific todo
- POST /todos - Create a new todo
  ```json
  {
    "title": "Buy groceries"
  }
  ```
- PUT /todos/{id} - Update a todo
  ```json
  {
    "title": "Updated title",
    "completed": true
  }
  ```
- DELETE /todos/{id} - Delete a todo

### Notes API
- GET /notes - List all notes
- GET /notes/{id} - Get a specific note
- POST /notes - Create a new note
  ```json
  {
    "content": "Remember to call mom"
  }
  ```
- PUT /notes/{id} - Update a note
  ```json
  {
    "content": "Updated content"
  }
  ```
- DELETE /notes/{id} - Delete a note

## Security Features

1. **Authentication**
   - JWT-based authentication using Cognito
   - Required for all API endpoints

2. **Rate Limiting**
   - 1000 requests per IP address
   - Configurable through WAF rules

3. **Data Protection**
   - HTTPS encryption
   - Input validation
   - Secure data storage

## Testing the APIs

1. Create a user in Cognito:
```bash
aws cognito-idp sign-up \
  --client-id <your-client-id> \
  --username user@example.com \
  --password YourPassword123!
```

2. Get authentication token:
```bash
aws cognito-idp admin-initiate-auth \
  --user-pool-id <your-user-pool-id> \
  --client-id <your-client-id> \
  --auth-flow ADMIN_USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=user@example.com,PASSWORD=YourPassword123!
```

3. Test the APIs using curl:
```bash
# Create a todo
curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/dev/todos \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"title": "Buy groceries"}'

# List todos
curl https://<api-id>.execute-api.<region>.amazonaws.com/dev/todos \
  -H "Authorization: Bearer <your-token>"

# Create a note
curl -X POST https://<api-id>.execute-api.<region>.amazonaws.com/dev/notes \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"content": "Remember to call mom"}'

# List notes
curl https://<api-id>.execute-api.<region>.amazonaws.com/dev/notes \
  -H "Authorization: Bearer <your-token>"
```

## Cleanup

To delete all resources:
```bash
sam delete
```

## Security Considerations

1. **API Gateway Security**
   - WAF integration for DDoS protection
   - Rate limiting
   - Request validation

2. **Data Security**
   - Encryption at rest
   - Encryption in transit
   - Secure authentication
