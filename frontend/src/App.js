import React, { useState, useEffect } from "react";
import { Amplify } from "aws-amplify";
import { Authenticator } from "@aws-amplify/ui-react";
import "@aws-amplify/ui-react/styles.css";
import TodoList from "./components/TodoList";
import NoteList from "./components/NoteList";

// Configure Amplify
Amplify.configure({
  Auth: {
    region: "us-east-1",
    userPoolId: "us-east-1_malguUP4s",
    userPoolWebClientId: "6aosqe6tgct0m8fasnfvpur4cc",
  },
  API: {
    endpoints: [
      {
        name: "api",
        endpoint: "https://496ja981q2.execute-api.us-east-1.amazonaws.com/dev/",
      },
    ],
  },
});

function App() {
  const [activeTab, setActiveTab] = useState("todos");

  return (
    <Authenticator>
      {({ signOut, user }) => (
        <div className="min-h-screen bg-gray-100">
          <nav className="bg-white shadow-lg">
            <div className="max-w-7xl mx-auto px-4">
              <div className="flex justify-between h-16">
                <div className="flex">
                  <div className="flex-shrink-0 flex items-center">
                    <h1 className="text-xl font-bold">Secure App</h1>
                  </div>
                  <div className="ml-6 flex items-center space-x-4">
                    <button
                      onClick={() => setActiveTab("todos")}
                      className={`px-3 py-2 rounded-md text-sm font-medium ${
                        activeTab === "todos"
                          ? "bg-gray-900 text-white"
                          : "text-gray-700 hover:bg-gray-700 hover:text-white"
                      }`}
                    >
                      Todos
                    </button>
                    <button
                      onClick={() => setActiveTab("notes")}
                      className={`px-3 py-2 rounded-md text-sm font-medium ${
                        activeTab === "notes"
                          ? "bg-gray-900 text-white"
                          : "text-gray-700 hover:bg-gray-700 hover:text-white"
                      }`}
                    >
                      Notes
                    </button>
                  </div>
                </div>
                <div className="flex items-center">
                  <span className="text-gray-700 mr-4">{user.username}</span>
                  <button
                    onClick={signOut}
                    className="bg-red-500 hover:bg-red-700 text-white font-bold py-2 px-4 rounded"
                  >
                    Sign Out
                  </button>
                </div>
              </div>
            </div>
          </nav>

          <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
            {activeTab === "todos" ? <TodoList /> : <NoteList />}
          </main>
        </div>
      )}
    </Authenticator>
  );
}

export default App;
