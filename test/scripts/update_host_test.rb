require "test_helper"
require "tmpdir"
require "json"

load File.expand_path("../../scripts/update-host", __dir__)

describe :update_host do
  it "maps vim and claude/hooks to their overridden dotfile paths" do
    _(UpdateHost.dest_rel("vim")).must_equal File.join(".config", "vim")
    _(UpdateHost.dest_rel("claude/hooks")).must_equal File.join(".claude", "hooks")
  end

  it "falls back to a dotted basename for everything else" do
    _(UpdateHost.dest_rel("shell/bashrc")).must_equal ".bashrc"
    _(UpdateHost.dest_rel("git-templates")).must_equal ".git-templates"
  end

  describe "merge_claude_settings" do
    # CLAUDE_CONFIG_DIR (read fresh via ENV on every call) is used instead of
    # HOME, which UpdateHost caches as a frozen constant at load time and
    # would otherwise point tests at this machine's real ~/.claude.
    it "creates settings.json from the template when none exists" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          UpdateHost.merge_claude_settings
        end

        target = File.join(config_dir, "settings.json")
        data = JSON.parse(File.read(target))
        _(data.dig("hooks", "Stop", 0, "hooks", 0, "command")).must_equal "~/.claude/hooks/notify-stop.sh"
      end
    end

    it "keeps machine-local keys and is idempotent on re-merge" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          UpdateHost.merge_claude_settings

          target = File.join(config_dir, "settings.json")
          data = JSON.parse(File.read(target))
          data["permissions"] = { "allow" => ["Bash(ls)"] }
          File.write(target, JSON.generate(data))

          UpdateHost.merge_claude_settings
          after = JSON.parse(File.read(target))

          _(after.dig("permissions", "allow")).must_equal ["Bash(ls)"]
          _(after.dig("hooks", "SessionStart", 0, "hooks", 0, "command")).must_equal "~/.claude/hooks/session-start.sh"
        end
      end
    end
  end

  def with_env(vars)
    original = vars.keys.to_h { |k| [k, ENV[k]] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    original.each { |k, v| ENV[k] = v }
  end
end
