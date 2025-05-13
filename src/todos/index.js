const AWS = require("aws-sdk");
const { v4: uuidv4 } = require("uuid");

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.TABLE_NAME;

// Authentication middleware
const authenticateRequest = (event) => {
  const authHeader = event.headers.Authorization || event.headers.authorization;
  if (!authHeader) {
    throw new Error("Authorization header is required");
  }

  const token = authHeader.replace("Bearer ", "");
  // In a real implementation, you would validate the JWT token with Cognito
  // For this example, we'll just check if it exists
  if (!token) {
    throw new Error("Invalid token");
  }

  // Extract user information from the token
  // In a real implementation, this would be decoded from the JWT
  return {
    userId: "user123", // This would come from the decoded JWT
    username: "testuser",
  };
};

// Helper function for CORS headers
const corsHeaders = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
  "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
};

exports.handler = async (event) => {
  // Handle OPTIONS request
  if (event.httpMethod === "OPTIONS") {
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: "",
    };
  }

  try {
    // Authenticate the request
    const user = authenticateRequest(event);

    const method = event.httpMethod;
    const pathParams = event.pathParameters || {};

    switch (method) {
      case "GET":
        if (pathParams.id) {
          return await getTodo(pathParams.id, user);
        }
        return await getTodos(user);
      case "POST":
        return await createTodo(JSON.parse(event.body), user);
      case "PUT":
        if (!pathParams.id) {
          return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ message: "Todo ID is required" }),
          };
        }
        return await updateTodo(pathParams.id, JSON.parse(event.body), user);
      case "DELETE":
        if (!pathParams.id) {
          return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ message: "Todo ID is required" }),
          };
        }
        return await deleteTodo(pathParams.id, user);
      default:
        return {
          statusCode: 400,
          headers: corsHeaders,
          body: JSON.stringify({ message: "Unsupported method" }),
        };
    }
  } catch (error) {
    console.error("Error:", error);
    if (error.message.includes("Authorization")) {
      return {
        statusCode: 401,
        headers: corsHeaders,
        body: JSON.stringify({ message: error.message }),
      };
    }
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({ message: "Internal server error" }),
    };
  }
};

async function getTodos(user) {
  const params = {
    TableName: TABLE_NAME,
    FilterExpression: "userId = :userId",
    ExpressionAttributeValues: {
      ":userId": user.userId,
    },
  };

  const result = await dynamoDB.scan(params).promise();

  return {
    statusCode: 200,
    headers: corsHeaders,
    body: JSON.stringify(result.Items),
  };
}

async function getTodo(id, user) {
  const params = {
    TableName: TABLE_NAME,
    Key: { id },
  };

  const result = await dynamoDB.get(params).promise();

  if (!result.Item) {
    return {
      statusCode: 404,
      headers: corsHeaders,
      body: JSON.stringify({ message: "Todo not found" }),
    };
  }

  // Check if the todo belongs to the user
  if (result.Item.userId !== user.userId) {
    return {
      statusCode: 403,
      headers: corsHeaders,
      body: JSON.stringify({ message: "Access denied" }),
    };
  }

  return {
    statusCode: 200,
    headers: corsHeaders,
    body: JSON.stringify(result.Item),
  };
}

async function createTodo(todoData, user) {
  if (!todoData.title) {
    return {
      statusCode: 400,
      headers: corsHeaders,
      body: JSON.stringify({ message: "Title is required" }),
    };
  }

  const todo = {
    id: uuidv4(),
    userId: user.userId,
    username: user.username,
    title: todoData.title,
    completed: false,
    createdAt: new Date().toISOString(),
  };

  const params = {
    TableName: TABLE_NAME,
    Item: todo,
  };

  await dynamoDB.put(params).promise();

  return {
    statusCode: 201,
    headers: corsHeaders,
    body: JSON.stringify(todo),
  };
}

async function updateTodo(id, updateData, user) {
  const getParams = {
    TableName: TABLE_NAME,
    Key: { id },
  };

  const existingTodo = await dynamoDB.get(getParams).promise();

  if (!existingTodo.Item) {
    return {
      statusCode: 404,
      headers: corsHeaders,
      body: JSON.stringify({ message: "Todo not found" }),
    };
  }

  // Check if the todo belongs to the user
  if (existingTodo.Item.userId !== user.userId) {
    return {
      statusCode: 403,
      headers: corsHeaders,
      body: JSON.stringify({ message: "Access denied" }),
    };
  }

  const updatedTodo = {
    ...existingTodo.Item,
    ...updateData,
  };

  const params = {
    TableName: TABLE_NAME,
    Item: updatedTodo,
  };

  await dynamoDB.put(params).promise();

  return {
    statusCode: 200,
    headers: corsHeaders,
    body: JSON.stringify(updatedTodo),
  };
}

async function deleteTodo(id, user) {
  const getParams = {
    TableName: TABLE_NAME,
    Key: { id },
  };

  const existingTodo = await dynamoDB.get(getParams).promise();

  if (!existingTodo.Item) {
    return {
      statusCode: 404,
      headers: corsHeaders,
      body: JSON.stringify({ message: "Todo not found" }),
    };
  }

  // Check if the todo belongs to the user
  if (existingTodo.Item.userId !== user.userId) {
    return {
      statusCode: 403,
      headers: corsHeaders,
      body: JSON.stringify({ message: "Access denied" }),
    };
  }

  const params = {
    TableName: TABLE_NAME,
    Key: { id },
  };

  await dynamoDB.delete(params).promise();

  return {
    statusCode: 204,
    headers: corsHeaders,
    body: JSON.stringify({ message: "Todo deleted successfully" }),
  };
}
