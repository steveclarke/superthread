# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st notes", :cli do
  describe "notes list" do
    before do
      stub_api_get("test_workspace/notes", response: ApiFixtures::Notes::LIST)
    end

    it "lists all notes" do
      result = run_cli("notes", "list")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Meeting Notes")
      expect(result[:stdout]).to include("Standup Summary")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("notes", "list")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |n| n["title"] }).to include("Meeting Notes", "Standup Summary")
    end
  end

  describe "notes get NOTE_ID" do
    before do
      stub_api_get("test_workspace/notes/note-1", response: ApiFixtures::Notes::GET)
    end

    it "displays note details" do
      result = run_cli("notes", "get", "note-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Meeting Notes")
      expect(result[:stdout]).to include("note-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("notes", "get", "note-1")

      expect(json["id"]).to eq("note-1")
      expect(json["title"]).to eq("Meeting Notes")
    end
  end

  describe "notes create" do
    before do
      stub_api_post("test_workspace/notes", response: ApiFixtures::Notes::CREATE)
    end

    it "creates a new note" do
      result = run_cli("notes", "create",
        "--title=New Note",
        "--transcript=Meeting transcript content")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("New Note")
      expect(result[:stdout]).to include("note-new-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("notes", "create",
        "--title=New Note",
        "--transcript=Meeting transcript content")

      expect(json["id"]).to eq("note-new-1")
      expect(json["title"]).to eq("New Note")
    end
  end

  describe "notes delete NOTE_ID" do
    before do
      stub_api_get("test_workspace/notes/note-to-delete", response: ApiFixtures::Notes::DELETE)
      stub_api_delete("test_workspace/notes/note-to-delete")
    end

    it "deletes a note with -y" do
      result = run_cli("notes", "delete", "note-to-delete", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Note 'Note to Delete' deleted")
    end
  end
end
