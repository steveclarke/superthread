# frozen_string_literal: true

RSpec.describe Superthread::MentionFormatter do
  let(:workspace_id) { "ws-123" }
  let(:client) { instance_double(Superthread::Client) }
  let(:users_resource) { instance_double(Superthread::Resources::Users) }

  let(:members) do
    [
      instance_double(Superthread::Models::User,
        display_name: "Steve Clarke",
        user_identifier: "u-steve"),
      instance_double(Superthread::Models::User,
        display_name: "John Smith",
        user_identifier: "u-john")
    ]
  end

  before do
    allow(client).to receive(:users).and_return(users_resource)
    allow(users_resource).to receive(:members).with(workspace_id).and_return(members)
  end

  subject(:formatter) { described_class.new(client, workspace_id) }

  describe "#format" do
    it "converts a single mention to a user-mention tag" do
      result = formatter.format("Hey {{@Steve Clarke}}, check this")

      expect(result).to include('user-id="u-steve"')
      expect(result).to include('user-value="Steve Clarke"')
      expect(result).to include('data-type="mention"')
      expect(result).to include('denotation-char="@"')
      expect(result).to include("mention-time=")
      expect(result).not_to include("{{@Steve Clarke}}")
    end

    it "converts multiple mentions in one string" do
      result = formatter.format("{{@Steve Clarke}} and {{@John Smith}} should review this")

      expect(result).to include('user-id="u-steve"')
      expect(result).to include('user-id="u-john"')
      expect(result).not_to include("{{@")
    end

    it "matches names case-insensitively" do
      result = formatter.format("Hey {{@steve clarke}}")

      expect(result).to include('user-id="u-steve"')
      expect(result).to include('user-value="Steve Clarke"')
    end

    it "preserves original casing in the user-value attribute" do
      result = formatter.format("{{@STEVE CLARKE}}")

      expect(result).to include('user-value="Steve Clarke"')
    end

    it "leaves unmatched names as-is" do
      result = formatter.format("Hey {{@Unknown Person}}")

      expect(result).to eq("Hey {{@Unknown Person}}")
    end

    it "handles a mix of matched and unmatched mentions" do
      result = formatter.format("{{@Steve Clarke}} and {{@Nobody}}")

      expect(result).to include('user-id="u-steve"')
      expect(result).to include("{{@Nobody}}")
    end

    it "preserves escaped mentions as literal text" do
      result = formatter.format('Use \{{@Steve Clarke}} syntax to mention users')

      expect(result).to eq("Use {{@Steve Clarke}} syntax to mention users")
      expect(result).not_to include("user-mention")
    end

    it "handles escaped and real mentions in the same string" do
      result = formatter.format('Say \{{@Steve Clarke}} to tag {{@Steve Clarke}}')

      expect(result).to include("{{@Steve Clarke}}")
      expect(result).to include('user-id="u-steve"')
    end

    it "returns nil for nil content" do
      expect(formatter.format(nil)).to be_nil
    end

    it "returns content as-is when no mention pattern is present" do
      content = "Just a regular comment"
      result = formatter.format(content)

      expect(result).to eq(content)
      expect(users_resource).not_to have_received(:members)
    end

    it "returns content as-is when member fetch fails" do
      allow(users_resource).to receive(:members).and_raise(Superthread::ApiError.new("fail"))

      result = formatter.format("Hey {{@Steve Clarke}}")

      expect(result).to eq("Hey {{@Steve Clarke}}")
    end

    it "trims whitespace in mention names" do
      result = formatter.format("Hey {{@ Steve Clarke }}")

      expect(result).to include('user-id="u-steve"')
    end

    it "HTML-escapes attribute values for XSS defense" do
      evil_members = [
        instance_double(Superthread::Models::User,
          display_name: 'Evil "User',
          user_identifier: 'u-"><script>')
      ]
      allow(users_resource).to receive(:members).and_return(evil_members)

      result = formatter.format('Hey {{@Evil "User}}')

      expect(result).to include("u-&quot;&gt;&lt;script&gt;")
      expect(result).to include("Evil &quot;User")
      expect(result).not_to include("<script>")
    end

    it "includes a valid Unix timestamp in mention-time" do
      freeze_time = Time.now
      allow(Time).to receive(:now).and_return(freeze_time)

      result = formatter.format("{{@Steve Clarke}}")

      expect(result).to include("mention-time=\"#{freeze_time.to_i}\"")
    end

    it "skips members with nil display_name" do
      members_with_nil = [
        instance_double(Superthread::Models::User,
          display_name: nil,
          user_identifier: "u-ghost"),
        instance_double(Superthread::Models::User,
          display_name: "Steve Clarke",
          user_identifier: "u-steve")
      ]
      allow(users_resource).to receive(:members).and_return(members_with_nil)

      result = formatter.format("{{@Steve Clarke}}")
      expect(result).to include('user-id="u-steve"')
    end

    context "when mentions don't resolve" do
      it "warns about unresolved mentions" do
        expect { formatter.format("Hey {{@Unknown Person}}") }.to output(
          /Could not resolve mention: Unknown Person/
        ).to_stderr
      end

      it "warns about each unresolved mention separately" do
        expect { formatter.format("{{@Nobody}} and {{@Ghost}}") }.to output(
          /Could not resolve mention: Nobody.*Could not resolve mention: Ghost/m
        ).to_stderr
      end

      it "does not warn for resolved mentions" do
        expect { formatter.format("{{@Steve Clarke}}") }.not_to output.to_stderr
      end

      it "warns only for unresolved ones in a mix" do
        expect { formatter.format("{{@Steve Clarke}} and {{@Nobody}}") }.to output(
          /Could not resolve mention: Nobody/
        ).to_stderr
      end
    end

    context "when content contains raw HTML mention tags" do
      it "warns about <user-mention> tags" do
        content = '<p><user-mention user-id="u123">Steve</user-mention> check this</p>'
        expect { formatter.format(content) }.to output(
          /Use \{\{@Name\}\} syntax to mention users/
        ).to_stderr
      end

      it "warns about <mention-user> tags" do
        content = '<p><mention-user user-id="u123">Steve</mention-user> check this</p>'
        expect { formatter.format(content) }.to output(
          /Use \{\{@Name\}\} syntax to mention users/
        ).to_stderr
      end

      it "still sends the content through unchanged" do
        content = '<p><user-mention user-id="u123">Steve</user-mention></p>'
        result = nil
        expect { result = formatter.format(content) }.to output(anything).to_stderr
        expect(result).to eq(content)
      end
    end
  end
end
