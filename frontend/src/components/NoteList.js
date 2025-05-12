import React, { useState, useEffect } from "react";
import { API } from "aws-amplify";
import { PlusIcon, TrashIcon, PencilIcon } from "@heroicons/react/24/outline";

function NoteList() {
  const [notes, setNotes] = useState([]);
  const [newNote, setNewNote] = useState("");
  const [editingNote, setEditingNote] = useState(null);

  useEffect(() => {
    fetchNotes();
  }, []);

  const fetchNotes = async () => {
    try {
      const response = await API.get("api", "/notes");
      setNotes(response);
    } catch (error) {
      console.error("Error fetching notes:", error);
    }
  };

  const createNote = async (e) => {
    e.preventDefault();
    if (!newNote.trim()) return;

    try {
      const note = {
        content: newNote,
      };
      await API.post("api", "/notes", { body: note });
      setNewNote("");
      fetchNotes();
    } catch (error) {
      console.error("Error creating note:", error);
    }
  };

  const updateNote = async (id, updates) => {
    try {
      await API.put("api", `/notes/${id}`, { body: updates });
      fetchNotes();
      setEditingNote(null);
    } catch (error) {
      console.error("Error updating note:", error);
    }
  };

  const deleteNote = async (id) => {
    try {
      await API.del("api", `/notes/${id}`);
      fetchNotes();
    } catch (error) {
      console.error("Error deleting note:", error);
    }
  };

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <h2 className="text-2xl font-bold mb-4">Notes</h2>

      <form onSubmit={createNote} className="mb-6">
        <div className="flex gap-2">
          <textarea
            value={newNote}
            onChange={(e) => setNewNote(e.target.value)}
            placeholder="Add a new note..."
            className="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 min-h-[100px]"
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

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {notes.map((note) => (
          <div
            key={note.id}
            className="bg-gray-50 rounded-lg p-4 relative group"
          >
            {editingNote === note.id ? (
              <textarea
                defaultValue={note.content}
                onBlur={(e) => updateNote(note.id, { content: e.target.value })}
                className="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 min-h-[100px]"
                autoFocus
              />
            ) : (
              <>
                <p className="text-gray-700 whitespace-pre-wrap">
                  {note.content}
                </p>
                <div className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <div className="flex gap-2">
                    <button
                      onClick={() => setEditingNote(note.id)}
                      className="text-gray-500 hover:text-gray-700"
                    >
                      <PencilIcon className="h-5 w-5" />
                    </button>
                    <button
                      onClick={() => deleteNote(note.id)}
                      className="text-red-500 hover:text-red-700"
                    >
                      <TrashIcon className="h-5 w-5" />
                    </button>
                  </div>
                </div>
              </>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default NoteList;
