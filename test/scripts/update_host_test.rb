require "test_helper"
require "tmpdir"
require "json"
require "stringio"
require "fileutils"

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

    it "does not duplicate a hook the live file rewrote to an absolute path" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          UpdateHost.merge_claude_settings
          target = File.join(config_dir, "settings.json")

          # Claude Code expands ~ to an absolute path when it rewrites the file.
          data = JSON.parse(File.read(target))
          %w[SessionStart Stop].each do |ev|
            cmd = data["hooks"][ev][0]["hooks"][0]["command"]
            data["hooks"][ev][0]["hooks"][0]["command"] = cmd.sub(%r{\A~/}, "#{ENV["HOME"]}/")
          end
          File.write(target, JSON.generate(data))

          UpdateHost.merge_claude_settings
          UpdateHost.merge_claude_settings # must stay stable across runs

          after = JSON.parse(File.read(target))
          # SessionStart has 2 distinct template entries (session-start.sh,
          # check-claude-version.sh); only the first was rewritten here, so
          # dedup must keep both rather than collapsing them into one.
          _(after.dig("hooks", "SessionStart").size).must_equal 2
          _(after.dig("hooks", "Stop").size).must_equal 1
          _(after.dig("hooks", "SessionStart", 0, "hooks").size).must_equal 1
          # the live (absolute) form is the one kept
          _(after.dig("hooks", "SessionStart", 0, "hooks", 0, "command"))
            .must_equal "#{ENV["HOME"]}/.claude/hooks/session-start.sh"
        end
      end
    end

    it "unions new permission-allow entries from the template" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          UpdateHost.merge_claude_settings
          target = File.join(config_dir, "settings.json")

          data = JSON.parse(File.read(target))
          data["permissions"] = { "allow" => ["Bash(ls)"] }
          File.write(target, JSON.generate(data))

          # a template that adds a permission
          tmpl = JSON.parse(File.read(File.join(UpdateHost::REPO_ROOT, "share", "claude", "settings.json.example")))
          merged = UpdateHost.deep_merge(
            tmpl.merge("permissions" => { "allow" => ["Bash(pwd)"] }),
            data
          )

          _(merged.dig("permissions", "allow")).must_equal ["Bash(ls)", "Bash(pwd)"]
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

  describe "verify_symlinks" do
    it "reports ok for a correct symlink, fail for wrong/missing, warn for a real file" do
      Dir.mktmpdir do |home|
        FileUtils.mkdir_p(File.join(home, ".config"))
        File.symlink(File.join(UpdateHost::REPO_ROOT, "share", "vim"), File.join(home, ".config", "vim"))
        File.symlink("/nowhere", File.join(home, ".bashrc"))
        FileUtils.mkdir_p(File.join(home, ".mutt"))

        out = StringIO.new
        v = UpdateHost::Verifier.new(io: out)
        UpdateHost.verify_symlinks(v, home: home, repo_root: UpdateHost::REPO_ROOT)

        _(out.string).must_include "ok    ~/.config/vim"
        _(out.string).must_include "FAIL  ~/.bashrc points to /nowhere"
        _(out.string).must_include "FAIL  ~/.inputrc missing"
        _(out.string).must_include "warn  ~/.mutt is a real file/dir"
        _(v.failed?).must_equal true
      end
    end
  end

  describe "verify_claude_settings" do
    it "is ok once merge_claude_settings has run" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          UpdateHost.merge_claude_settings

          out = StringIO.new
          v = UpdateHost::Verifier.new(io: out)
          UpdateHost.verify_claude_settings(v, home: config_dir, repo_root: UpdateHost::REPO_ROOT)

          _(v.failed?).must_equal false
          _(out.string).must_include "ok    #{File.join(config_dir, 'settings.json')}"
        end
      end
    end

    it "fails when the live file is missing template keys" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          File.write(File.join(config_dir, "settings.json"), "{}")

          out = StringIO.new
          v = UpdateHost::Verifier.new(io: out)
          UpdateHost.verify_claude_settings(v, home: config_dir, repo_root: UpdateHost::REPO_ROOT)

          _(v.failed?).must_equal true
          _(out.string).must_include "missing keys from the template"
        end
      end
    end

    it "warns (does not fail) on malformed JSON, matching merge_claude_settings's own no-op" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          File.write(File.join(config_dir, "settings.json"), "not json")

          out = StringIO.new
          v = UpdateHost::Verifier.new(io: out)
          UpdateHost.verify_claude_settings(v, home: config_dir, repo_root: UpdateHost::REPO_ROOT)

          _(v.failed?).must_equal false
          _(out.string).must_include "warn"
          _(out.string).must_include "not valid JSON"
        end
      end
    end

    it "warns about a symlinked settings.json but still checks the content underneath" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          UpdateHost.merge_claude_settings
          real = File.join(config_dir, "settings.json")
          moved = File.join(config_dir, "settings.actual.json")
          FileUtils.mv(real, moved)
          File.symlink(moved, real)

          out = StringIO.new
          v = UpdateHost::Verifier.new(io: out)
          UpdateHost.verify_claude_settings(v, home: config_dir, repo_root: UpdateHost::REPO_ROOT)

          _(v.failed?).must_equal false
          _(out.string).must_include "warn  #{real} is a symlink"
          _(out.string).must_include "ok    #{real} has all template keys merged"
        end
      end
    end
  end

  describe "verify_hook_executability" do
    it "reports ok for +x hooks and fail for non-executable ones" do
      Dir.mktmpdir do |repo_root|
        hooks_dir = File.join(repo_root, "share", "claude", "hooks")
        FileUtils.mkdir_p(hooks_dir)
        exe = File.join(hooks_dir, "good.sh")
        File.write(exe, "#!/usr/bin/env bash\n")
        FileUtils.chmod(0o755, exe)
        not_exe = File.join(hooks_dir, "bad.sh")
        File.write(not_exe, "#!/usr/bin/env bash\n")
        FileUtils.chmod(0o644, not_exe)

        out = StringIO.new
        v = UpdateHost::Verifier.new(io: out)
        UpdateHost.verify_hook_executability(v, repo_root: repo_root)

        _(out.string).must_include "ok    #{exe} is executable"
        _(out.string).must_include "FAIL  #{not_exe} is not executable"
      end
    end

    it "fails the section rather than silently passing when no hooks are found" do
      Dir.mktmpdir do |repo_root|
        out = StringIO.new
        v = UpdateHost::Verifier.new(io: out)
        UpdateHost.verify_hook_executability(v, repo_root: repo_root)

        _(v.failed?).must_equal true
        _(out.string).must_include "FAIL  no hook files found matching"
      end
    end
  end

  describe "check_git_config" do
    it "reports ok when the value matches and warn when it doesn't" do
      key = "update-host-test.verify-check"

      Dir.mktmpdir do |gitconfig_dir|
        with_env("GIT_CONFIG_GLOBAL" => File.join(gitconfig_dir, "gitconfig")) do
          system("git", "config", "--global", key, "/tmp/expected-path", out: File::NULL)

          out = StringIO.new
          v = UpdateHost::Verifier.new(io: out)
          UpdateHost.check_git_config(v, key, "/tmp/expected-path", home: "/tmp")
          _(out.string).must_include "ok    git #{key}"

          system("git", "config", "--global", key, "/tmp/other-path", out: File::NULL)

          out2 = StringIO.new
          v2 = UpdateHost::Verifier.new(io: out2)
          UpdateHost.check_git_config(v2, key, "/tmp/expected-path", home: "/tmp")
          _(out2.string).must_include "warn"
        end
      end
    end

    it "warns rather than misreporting 'unset' when git itself fails" do
      key = "update-host-test.verify-check"

      Dir.mktmpdir do |gitconfig_dir|
        # A directory where git expects a file: `git config --get` exits 128
        # with a real error on stderr, not the ordinary "key unset" exit 1.
        broken = File.join(gitconfig_dir, "gitconfig")
        FileUtils.mkdir_p(broken)

        with_env("GIT_CONFIG_GLOBAL" => broken) do
          out = StringIO.new
          v = UpdateHost::Verifier.new(io: out)
          UpdateHost.check_git_config(v, key, "/tmp/expected-path", home: "/tmp")

          _(v.failed?).must_equal false
          _(out.string).must_include "warn"
          _(out.string).must_include "could not read git #{key}"
        end
      end
    end
  end

  describe "verify_claude_version" do
    it "warns distinctly when `claude --version` itself fails, instead of looking unverified" do
      Dir.mktmpdir do |bin_dir|
        fake_claude = File.join(bin_dir, "claude")
        File.write(fake_claude, "#!/usr/bin/env bash\nexit 3\n")
        FileUtils.chmod(0o755, fake_claude)

        Dir.mktmpdir do |config_dir|
          with_env(
            "PATH" => "#{bin_dir}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH', '')}",
            "CLAUDE_CONFIG_DIR" => config_dir
          ) do
            out = StringIO.new
            v = UpdateHost::Verifier.new(io: out)
            UpdateHost.verify_claude_version(v)

            _(v.failed?).must_equal false
            _(out.string).must_include "exited 3"
          end
        end
      end
    end
  end

  describe "verify_submodule" do
    it "is ok when nerdtree is initialized, fail when missing" do
      Dir.mktmpdir do |repo_root|
        nerdtree = File.join(repo_root, "share", "vim", "pack", "vendor", "start", "nerdtree")

        out = StringIO.new
        v = UpdateHost::Verifier.new(io: out)
        UpdateHost.verify_submodule(v, repo_root: repo_root)
        _(v.failed?).must_equal true

        FileUtils.mkdir_p(nerdtree)
        File.write(File.join(nerdtree, "placeholder"), "x")

        out2 = StringIO.new
        v2 = UpdateHost::Verifier.new(io: out2)
        UpdateHost.verify_submodule(v2, repo_root: repo_root)
        _(v2.failed?).must_equal false
      end
    end
  end

  describe "verify_supporting_paths" do
    it "is ok when all three exist, fail when absent" do
      Dir.mktmpdir do |home|
        out = StringIO.new
        v = UpdateHost::Verifier.new(io: out)
        UpdateHost.verify_supporting_paths(v, home: home)
        _(v.failed?).must_equal true

        FileUtils.mkdir_p(File.join(home, ".backup"), mode: 0o700)
        FileUtils.mkdir_p(File.join(home, "tmp"))
        FileUtils.touch(File.join(home, ".signaturerc"))

        out2 = StringIO.new
        v2 = UpdateHost::Verifier.new(io: out2)
        UpdateHost.verify_supporting_paths(v2, home: home)
        _(v2.failed?).must_equal false
      end
    end
  end

  describe "command_on_path?" do
    it "finds a real command and rejects a nonexistent one" do
      _(UpdateHost.command_on_path?("ruby")).must_equal true
      _(UpdateHost.command_on_path?("not-a-real-command-xyz")).must_equal false
    end
  end

  describe "verify_local" do
    def build_matching_home(home, config_dir)
      FileUtils.mkdir_p(File.join(home, ".backup"), mode: 0o700)
      FileUtils.mkdir_p(File.join(home, "tmp"))
      FileUtils.touch(File.join(home, ".signaturerc"))

      UpdateHost::CONFIG_FILES.each do |rel|
        dotfile = File.join(home, UpdateHost.dest_rel(rel))
        target = File.join(UpdateHost::REPO_ROOT, "share", rel)
        FileUtils.mkdir_p(File.dirname(dotfile))
        File.symlink(target, dotfile)
      end

      with_env("CLAUDE_CONFIG_DIR" => config_dir) { UpdateHost.merge_claude_settings }
    end

    def run_verify(home, config_dir)
      out = StringIO.new
      code = with_env("CLAUDE_CONFIG_DIR" => config_dir) do
        begin
          UpdateHost.verify_local(home: home, repo_root: UpdateHost::REPO_ROOT, io: out)
          0
        rescue SystemExit => e
          e.status
        end
      end
      [code, out.string]
    end

    it "exits 0 when this repo's real hooks/submodule and a matching home agree" do
      Dir.mktmpdir do |home|
        Dir.mktmpdir do |config_dir|
          build_matching_home(home, config_dir)
          code, = run_verify(home, config_dir)
          _(code).must_equal 0
        end
      end
    end

    it "exits 1 when a symlink is broken" do
      Dir.mktmpdir do |home|
        Dir.mktmpdir do |config_dir|
          build_matching_home(home, config_dir)
          File.unlink(File.join(home, ".bashrc"))

          code, output = run_verify(home, config_dir)
          _(code).must_equal 1
          _(output).must_include "FAIL  ~/.bashrc missing"
        end
      end
    end
  end
end
