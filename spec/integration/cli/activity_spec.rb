# frozen_string_literal: true

require "spec_helper"

RSpec.describe "st activity", :cli do
  let(:now) { Time.new(2025, 1, 20, 12, 0, 0) }
  let(:today_ts) { Time.new(2025, 1, 20, 10, 0, 0).to_i * 1000 }  # 10am today in ms
  let(:yesterday_ts) { Time.new(2025, 1, 19, 14, 0, 0).to_i * 1000 }  # yesterday in ms
  let(:old_ts) { Time.new(2025, 1, 10, 10, 0, 0).to_i * 1000 }  # 10 days ago in ms

  before do
    allow(Date).to receive(:today).and_return(now.to_date)
    allow(Time).to receive(:now).and_return(now)
  end

  describe "activity show" do
    context "with --user filter" do
      before do
        stub_api_post("test_workspace/views/preview", response: {
          cards: [
            {
              id: "card-1",
              title: "Created today",
              status: "not_started",
              priority: 2,
              list_title: "To Do",
              board_title: "Sprint Board",
              time_created: today_ts,
              time_updated: today_ts
            },
            {
              id: "card-2",
              title: "Updated today",
              status: "started",
              priority: 3,
              list_title: "In Progress",
              board_title: "Sprint Board",
              time_created: old_ts,
              time_updated: today_ts
            },
            {
              id: "card-3",
              title: "Old card",
              status: "started",
              priority: 1,
              list_title: "Done",
              board_title: "Sprint Board",
              time_created: old_ts,
              time_updated: old_ts
            }
          ]
        })
      end

      it "shows activity for a user" do
        result = run_cli("activity", "--user=u123abc", "--since=today")

        expect(result[:exit_code]).to eq(0)
        expect(result[:stdout]).to include("Created today")
        expect(result[:stdout]).to include("Updated today")
        expect(result[:stdout]).not_to include("Old card")
      end

      it "outputs JSON with --json flag" do
        json = cli_json("activity", "--user=u123abc", "--since=today")

        expect(json).to have_key("created")
        expect(json).to have_key("updated")
        expect(json).to have_key("completed")
        expect(json).to have_key("summary")
        expect(json["summary"]["total_created"]).to eq(1)
        expect(json["summary"]["total_updated"]).to eq(1)
      end
    end

    context "with --board filter" do
      before do
        stub_api_post("test_workspace/views/preview", response: {
          cards: [
            {
              id: "card-1",
              title: "Board card",
              status: "not_started",
              list_title: "To Do",
              board_title: "Sprint Board",
              time_created: today_ts,
              time_updated: today_ts
            }
          ]
        })
      end

      it "shows activity for a board" do
        result = run_cli("activity", "--board=10", "--since=today")

        expect(result[:exit_code]).to eq(0)
        expect(result[:stdout]).to include("Board card")
      end
    end

    context "with completed cards" do
      before do
        stub_api_post("test_workspace/views/preview", response: {
          cards: [
            {
              id: "card-1",
              title: "Completed task",
              status: "completed",
              list_title: "Done",
              board_title: "Sprint Board",
              time_created: old_ts,
              time_updated: today_ts,
              completed_date: today_ts
            }
          ]
        })
      end

      it "shows completed cards" do
        result = run_cli("activity", "--user=me", "--since=today")

        expect(result[:exit_code]).to eq(0)
        expect(result[:stdout]).to include("Completed")
        expect(result[:stdout]).to include("Completed task")
      end
    end

    context "with no activity" do
      before do
        stub_api_post("test_workspace/views/preview", response: {
          cards: [
            {
              id: "card-1",
              title: "Old card",
              status: "started",
              time_created: old_ts,
              time_updated: old_ts
            }
          ]
        })
      end

      it "shows no activity message" do
        result = run_cli("activity", "--user=me", "--since=today")

        expect(result[:exit_code]).to eq(0)
        expect(result[:stdout]).to include("No activity since today")
      end
    end
  end

  describe "activity with date filters" do
    before do
      stub_api_post("test_workspace/views/preview", response: {
        cards: [
          {
            id: "card-1",
            title: "Friday card",
            status: "started",
            time_created: Time.new(2025, 1, 17, 10, 0, 0).to_i * 1000,
            time_updated: Time.new(2025, 1, 17, 10, 0, 0).to_i * 1000
          }
        ]
      })
    end

    it "accepts natural language dates" do
      result = run_cli("activity", "--user=me", "--since=friday")

      expect(result[:exit_code]).to eq(0)
      expect(result[:stdout]).to include("Friday card")
    end

    it "accepts '3 days ago'" do
      result = run_cli("activity", "--user=me", "--since=3 days ago")

      expect(result[:exit_code]).to eq(0)
      # Should include Friday card (3 days ago from Jan 20 is Jan 17)
      expect(result[:stdout]).to include("Friday card")
    end
  end
end
