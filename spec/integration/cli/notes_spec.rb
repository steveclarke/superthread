# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st notes", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "notes list" do
    it "lists all notes", vcr: {cassette_name: "cli/notes_list"} do
      result = run_cli("notes", "list")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Meeting Notes")
      expect(result[:stdout]).to include("Standup Summary")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/notes_list"} do
      json = cli_json("notes", "list")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |n| n["title"] }).to include("Meeting Notes", "Standup Summary")
    end
  end

  describe "notes get NOTE_ID" do
    it "displays note details", vcr: {cassette_name: "cli/notes_get"} do
      result = run_cli("notes", "get", "note-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Meeting Notes")
      expect(result[:stdout]).to include("note-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/notes_get"} do
      json = cli_json("notes", "get", "note-1")

      expect(json["id"]).to eq("note-1")
      expect(json["title"]).to eq("Meeting Notes")
    end
  end

  describe "notes create" do
    it "creates a new note", vcr: {cassette_name: "cli/notes_create"} do
      result = run_cli("notes", "create",
        "--title=New Note",
        "--transcript=Meeting transcript content")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("New Note")
      expect(result[:stdout]).to include("note-new-1")
    end

    it "outputs JSON with --json flag", vcr: {cassette_name: "cli/notes_create"} do
      json = cli_json("notes", "create",
        "--title=New Note",
        "--transcript=Meeting transcript content")

      expect(json["id"]).to eq("note-new-1")
      expect(json["title"]).to eq("New Note")
    end
  end

  describe "notes delete NOTE_ID" do
    it "deletes a note", vcr: {cassette_name: "cli/notes_delete"} do
      result = run_cli("notes", "delete", "note-to-delete")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Note note-to-delete deleted")
    end
  end
end
