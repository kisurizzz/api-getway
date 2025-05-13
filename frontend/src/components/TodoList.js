import React, { useState, useEffect } from "react";
import { API, Auth } from "aws-amplify";
import { PlusIcon, TrashIcon, PencilIcon } from "@heroicons/react/24/outline";

function TodoList() {
  const [todos, setTodos] = useState([]);
  const [newTodo, setNewTodo] = useState("");
  const [editingTodo, setEditingTodo] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const session = await Auth.currentSession();
        console.log("Current session:", session);
        console.log("ID Token:", session.getIdToken().getJwtToken());
        // If we have a valid session, fetch todos
        fetchTodos();
      } catch (error) {
        console.error("Auth error:", error);
        setError("Authentication error. Please try logging in again.");
      }
    };
    checkAuth();
  }, []);

  const fetchTodos = async () => {
    try {
      setError(null);
      console.log("Fetching todos...");
      const response = await API.get("api", "/todos");
      console.log("Todos response:", response);
      setTodos(response);
    } catch (error) {
      console.error("Error fetching todos:", error);
      if (error.response?.status === 401) {
        setError("Authentication error - please try logging in again");
      } else if (error.message === "Network Error") {
        setError(
          "CORS error - Unable to connect to the server. Please check your connection."
        );
      } else {
        setError("Error fetching todos. Please try again later.");
      }
      console.error("Error details:", {
        message: error.message,
        status: error.response?.status,
        data: error.response?.data,
      });
    }
  };

  const createTodo = async (e) => {
    e.preventDefault();
    if (!newTodo.trim()) return;

    try {
      setError(null);
      console.log("Creating todo...");
      const todo = {
        title: newTodo,
        completed: false,
      };
      console.log("Todo payload:", todo);
      const response = await API.post("api", "/todos", { body: todo });
      console.log("Create todo response:", response);
      setNewTodo("");
      fetchTodos();
    } catch (error) {
      console.error("Error creating todo:", error);
      setError("Error creating todo. Please try again.");
      console.error("Error details:", {
        message: error.message,
        status: error.response?.status,
        data: error.response?.data,
      });
    }
  };

  const updateTodo = async (id, updates) => {
    try {
      setError(null);
      await API.put("api", `/todos/${id}`, { body: updates });
      fetchTodos();
      setEditingTodo(null);
    } catch (error) {
      console.error("Error updating todo:", error);
      setError("Error updating todo. Please try again.");
    }
  };

  const deleteTodo = async (id) => {
    try {
      setError(null);
      await API.del("api", `/todos/${id}`);
      fetchTodos();
    } catch (error) {
      console.error("Error deleting todo:", error);
      setError("Error deleting todo. Please try again.");
    }
  };

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <h2 className="text-2xl font-bold mb-4">Todos</h2>

      {error && (
        <div className="mb-4 p-4 bg-red-100 border border-red-400 text-red-700 rounded">
          {error}
        </div>
      )}

      <form onSubmit={createTodo} className="mb-6">
        <div className="flex gap-2">
          <input
            type="text"
            value={newTodo}
            onChange={(e) => setNewTodo(e.target.value)}
            placeholder="Add a new todo..."
            className="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
          />
          <button
            type="submit"
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <PlusIcon className="h-5 w-5 mr-2" />
            Add
          </button>
        </div>
      </form>

      <ul className="space-y-3">
        {todos.map((todo) => (
          <li
            key={todo.id}
            className="flex items-center justify-between p-4 bg-gray-50 rounded-lg"
          >
            {editingTodo === todo.id ? (
              <input
                type="text"
                defaultValue={todo.title}
                onBlur={(e) => updateTodo(todo.id, { title: e.target.value })}
                className="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                autoFocus
              />
            ) : (
              <div className="flex items-center flex-1">
                <input
                  type="checkbox"
                  checked={todo.completed}
                  onChange={(e) =>
                    updateTodo(todo.id, { completed: e.target.checked })
                  }
                  className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded mr-3"
                />
                <span
                  className={`flex-1 ${
                    todo.completed ? "line-through text-gray-500" : ""
                  }`}
                >
                  {todo.title}
                </span>
              </div>
            )}
            <div className="flex gap-2">
              <button
                onClick={() => setEditingTodo(todo.id)}
                className="text-gray-500 hover:text-gray-700"
              >
                <PencilIcon className="h-5 w-5" />
              </button>
              <button
                onClick={() => deleteTodo(todo.id)}
                className="text-red-500 hover:text-red-700"
              >
                <TrashIcon className="h-5 w-5" />
              </button>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default TodoList;
