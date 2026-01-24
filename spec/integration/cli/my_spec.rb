# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st my", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "my cards" do
    before do
      stub_api_get("users/me", response: ApiFixtures::Users::ME)
      stub_api_post("test_workspace/views/preview", response: ApiFixtures::Cards::ASSIGNED)
    end

    it "lists cards assigned to me" do
      result = run_cli("my", "cards")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Implement feature X")
      expect(result[:stdout]).to include("Fix bug Y")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("my", "cards")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
    end
  end

  describe "my cards with date filters" do
    let(:now) { Time.now }
    let(:today_start) { Time.new(now.year, now.month, now.day).to_i * 1000 }
    let(:yesterday) { today_start - (24 * 60 * 60 * 1000) }
    let(:tomorrow) { today_start + (24 * 60 * 60 * 1000) }

    before do
      stub_api_get("users/me", response: ApiFixtures::Users::ME)
    end

    it "filters overdue cards" do
      stub_api_post("test_workspace/views/preview", response: {
        cards: [
          {id: "card-1", title: "Overdue task", due_date: yesterday, list_title: "To Do"},
          {id: "card-2", title: "Future task", due_date: tomorrow, list_title: "To Do"}
        ]
      })

      result = run_cli("my", "cards", "--overdue")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Overdue task")
      expect(result[:stdout]).not_to include("Future task")
    end

    it "filters cards due today" do
      stub_api_post("test_workspace/views/preview", response: {
        cards: [
          {id: "card-1", title: "Today task", due_date: today_start + 1000, list_title: "To Do"},
          {id: "card-2", title: "Tomorrow task", due_date: tomorrow, list_title: "To Do"}
        ]
      })

      result = run_cli("my", "cards", "--today")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Today task")
      expect(result[:stdout]).not_to include("Tomorrow task")
    end
  end

  describe "my boards" do
    before do
      stub_api_get("test_workspace/projects", response: ApiFixtures::Spaces::LIST)
      stub_request(:get, "https://api.superthread.com/v1/test_workspace/boards")
        .with(query: hash_including(project_id: "1"))
        .to_return(status: 200, body: {boards: [{id: "10", title: "Sprint Board", space_id: "1"}]}.to_json,
          headers: {"Content-Type" => "application/json"})
      stub_request(:get, "https://api.superthread.com/v1/test_workspace/boards")
        .with(query: hash_including(project_id: "2"))
        .to_return(status: 200, body: {boards: [{id: "11", title: "Design Board", space_id: "2"}]}.to_json,
          headers: {"Content-Type" => "application/json"})
    end

    it "lists all boards across spaces" do
      result = run_cli("my", "boards")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Sprint Board")
      expect(result[:stdout]).to include("Design Board")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("my", "boards")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
    end
  end

  describe "my boards with space filter" do
    before do
      stub_request(:get, "https://api.superthread.com/v1/test_workspace/boards")
        .with(query: hash_including(project_id: "1"))
        .to_return(status: 200, body: ApiFixtures::Boards::LIST.to_json,
          headers: {"Content-Type" => "application/json"})
    end

    it "filters boards by space" do
      result = run_cli("my", "boards", "-s", "1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Sprint Board")
    end
  end

  describe "my workspaces" do
    before do
      stub_api_get("users/me", response: ApiFixtures::Workspaces::LIST)
    end

    it "lists workspaces" do
      result = run_cli("my", "workspaces")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("My Team")
      expect(result[:stdout]).to include("Other Team")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("my", "workspaces")

      expect(json).to have_key("teams")
      expect(json["teams"].length).to eq(2)
    end
  end
end
