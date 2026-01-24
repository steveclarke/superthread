# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st pages", :cli do
  before do
    ENV["SUPERTHREAD_API_KEY"] = "test_key"
    ENV["SUPERTHREAD_WORKSPACE_ID"] = "test_workspace"
  end

  describe "pages list" do
    before do
      stub_api_get("test_workspace/pages", response: ApiFixtures::Pages::LIST)
    end

    it "lists all pages" do
      result = run_cli("pages", "list")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Getting Started")
      expect(result[:stdout]).to include("API Documentation")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("pages", "list")

      expect(json).to be_an(Array)
      expect(json.length).to eq(2)
      expect(json.map { |p| p["title"] }).to include("Getting Started", "API Documentation")
    end
  end

  describe "pages get PAGE_ID" do
    before do
      stub_api_get("test_workspace/pages/page-1", response: ApiFixtures::Pages::GET)
    end

    it "displays page details" do
      result = run_cli("pages", "get", "page-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Getting Started")
      expect(result[:stdout]).to include("page-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("pages", "get", "page-1")

      expect(json["id"]).to eq("page-1")
      expect(json["title"]).to eq("Getting Started")
      expect(json["space_id"]).to eq("1")
    end
  end

  describe "pages create" do
    before do
      stub_api_post("test_workspace/pages", response: ApiFixtures::Pages::CREATE)
    end

    it "creates a new page" do
      result = run_cli("pages", "create",
        "--space=1",
        "--title=New Page",
        "--content=Page content here")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("New Page")
      expect(result[:stdout]).to include("page-new-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("pages", "create",
        "--space=1",
        "--title=New Page",
        "--content=Page content here")

      expect(json["id"]).to eq("page-new-1")
      expect(json["title"]).to eq("New Page")
      expect(json["space_id"]).to eq("1")
    end
  end

  describe "pages update PAGE_ID" do
    before do
      stub_api_patch("test_workspace/pages/page-1", response: ApiFixtures::Pages::UPDATE)
    end

    it "updates page attributes" do
      result = run_cli("pages", "update", "page-1", "--title=Updated Page Title")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Updated Page Title")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("pages", "update", "page-1", "--title=Updated Page Title")

      expect(json["id"]).to eq("page-1")
      expect(json["title"]).to eq("Updated Page Title")
    end
  end

  describe "pages duplicate PAGE_ID" do
    before do
      stub_api_post("test_workspace/pages/page-1/copy", response: ApiFixtures::Pages::DUPLICATE)
    end

    it "duplicates a page" do
      result = run_cli("pages", "duplicate", "page-1",
        "--space=1",
        "--title=Copy of Getting Started")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Copy of Getting Started")
      expect(result[:stdout]).to include("page-dup-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("pages", "duplicate", "page-1",
        "--space=1",
        "--title=Copy of Getting Started")

      expect(json["id"]).to eq("page-dup-1")
      expect(json["title"]).to eq("Copy of Getting Started")
    end
  end

  describe "pages archive PAGE_ID" do
    before do
      stub_api_patch("test_workspace/pages/page-1", response: ApiFixtures::Pages::ARCHIVE)
    end

    it "archives a page" do
      result = run_cli("pages", "archive", "page-1")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("page-1")
    end

    it "outputs JSON with --json flag" do
      json = cli_json("pages", "archive", "page-1")

      expect(json["id"]).to eq("page-1")
      expect(json["archived"]).to eq(true)
    end
  end

  describe "pages delete PAGE_ID" do
    before do
      stub_api_get("test_workspace/pages/page-to-delete", response: ApiFixtures::Pages::DELETE)
      stub_api_delete("test_workspace/pages/page-to-delete")
    end

    it "deletes a page with -y" do
      result = run_cli("pages", "delete", "page-to-delete", "-y")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Page 'Page to Delete' deleted")
    end
  end
end
