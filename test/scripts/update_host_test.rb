require "test_helper"
require "tmpdir"
require "json"
require "stringio"
require "fileutils"

load File.expand_path("../../scripts/update-host", __dir__)

describe :update_host do
  it "maps vim and agents-config/hooks to their overridden dotfile paths" do
    _(UpdateHost.dest_rel("vim")).must_equal File.join(".config", "vim")
    _(UpdateHost.dest_rel("agents-config/hooks")).must_equal File.join(".claude", "hooks")
  end

  it "falls back to a dotted basename for everything else" do
    _(UpdateHost.dest_rel("shell/bashrc")).must_equal ".bashrc"
    _(UpdateHost.dest_rel("git-templates")).must_equal ".git-templates"
  end

  describe "deep_merge" do
    it "keeps live values and unions template array entries" do
      merged = UpdateHost.deep_merge(
        { "model" => "a", "permissions" => { "allow" => ["Bash(pwd)"] } },
        { "model" => "b", "permissions" => { "allow" => ["Bash(ls)"] } }
      )

      _(merged).must_equal({ "model" => "b", "permissions" => { "allow" => ["Bash(ls)", "Bash(pwd)"] } })
    end

    it "treats a hook Claude Code rewrote to an absolute path as already present" do
      template = JSON.parse(File.read(claude_template))
      live = JSON.parse(File.read(claude_template))
      # Claude Code expands ~ to an absolute path when it rewrites the file.
      %w[SessionStart Stop].each do |ev|
        cmd = live["hooks"][ev][0]["hooks"][0]["command"]
        live["hooks"][ev][0]["hooks"][0]["command"] = cmd.sub(%r{\A~/}, "#{ENV["HOME"]}/")
      end

      _(UpdateHost.deep_merge(template, live)).must_equal live
    end
  end

  describe "relink" do
    it "leaves a symlink that points elsewhere alone and warns" do
      Dir.mktmpdir do |dir|
        link = File.join(dir, "link")
        File.symlink("/somewhere/else", link)

        _ { UpdateHost.relink(link, File.join(dir, "target")) }
          .must_output "", /leaving #{Regexp.escape(link)} -> \/somewhere\/else alone/
        _(File.readlink(link)).must_equal "/somewhere/else"
      end
    end

    it "is silent when the symlink already points at the target" do
      Dir.mktmpdir do |dir|
        link = File.join(dir, "link")
        target = File.join(dir, "target")
        File.symlink(target, link)

        _ { UpdateHost.relink(link, target) }.must_output "", ""
      end
    end
  end

  def claude_template
    File.join(UpdateHost::REPO_ROOT, "share", "agents-config", "settings.json.example")
  end

  def with_env(vars)
    original = vars.keys.to_h { |k| [k, ENV[k]] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    original.each { |k, v| ENV[k] = v }
  end

  describe "verify_symlinks" do
    it "reports ok for a correct symlink, fail for missing, warn for a foreign symlink or real file" do
      Dir.mktmpdir do |home|
        FileUtils.mkdir_p(File.join(home, ".config"))
        File.symlink(File.join(UpdateHost::REPO_ROOT, "share", "vim"), File.join(home, ".config", "vim"))
        File.symlink("/nowhere", File.join(home, ".bashrc"))
        FileUtils.mkdir_p(File.join(home, ".mutt"))

        out = StringIO.new
        v = UpdateHost::Verifier.new(io: out)
        UpdateHost.verify_symlinks(v, home: home, repo_root: UpdateHost::REPO_ROOT)

        _(out.string).must_include "ok    ~/.config/vim"
        _(out.string).must_include "warn  ~/.bashrc points to /nowhere"
        _(out.string).must_include "FAIL  ~/.inputrc missing"
        _(out.string).must_include "warn  ~/.mutt is a real file/dir"
        _(v.failed?).must_equal true
      end
    end

    it "is ok when ~/.claude/CLAUDE.md links to the AGENTS.md source, with no ~/.claude/AGENTS.md" do
      Dir.mktmpdir do |home|
        FileUtils.mkdir_p(File.join(home, ".claude"))
        File.symlink(File.join(UpdateHost::REPO_ROOT, "share", "agents-config", "AGENTS.md"), File.join(home, ".claude", "CLAUDE.md"))

        out = StringIO.new
        v = UpdateHost::Verifier.new(io: out)
        UpdateHost.verify_symlinks(v, home: home, repo_root: UpdateHost::REPO_ROOT)

        _(out.string).must_include "ok    ~/.claude/CLAUDE.md ->"
        _(out.string).wont_include "~/.claude/AGENTS.md"
      end
    end

    it "warns about a real (non-symlink) CLAUDE.md" do
      Dir.mktmpdir do |home|
        FileUtils.mkdir_p(File.join(home, ".claude"))
        File.write(File.join(home, ".claude", "CLAUDE.md"), "a real file the user wrote")

        out = StringIO.new
        v = UpdateHost::Verifier.new(io: out)
        UpdateHost.verify_symlinks(v, home: home, repo_root: UpdateHost::REPO_ROOT)

        _(out.string).must_include "warn  ~/.claude/CLAUDE.md is a real file/dir"
      end
    end

    it "fails when ~/.claude/CLAUDE.md is missing" do
      Dir.mktmpdir do |home|
        FileUtils.mkdir_p(File.join(home, ".claude"))

        out = StringIO.new
        v = UpdateHost::Verifier.new(io: out)
        UpdateHost.verify_symlinks(v, home: home, repo_root: UpdateHost::REPO_ROOT)

        _(out.string).must_include "FAIL  ~/.claude/CLAUDE.md missing"
        _(v.failed?).must_equal true
      end
    end
  end

  describe "link_claude_md" do
    it "symlinks ~/.claude/CLAUDE.md to the AGENTS.md source file" do
      Dir.mktmpdir do |home|
        FileUtils.mkdir_p(File.join(home, ".claude"))
        claude_md = File.join(home, ".claude", "CLAUDE.md")

        UpdateHost.link_claude_md(home: home, repo_root: UpdateHost::REPO_ROOT)

        _(File.symlink?(claude_md)).must_equal true
        _(File.readlink(claude_md)).must_equal File.join(UpdateHost::REPO_ROOT, "share", "agents-config", "AGENTS.md")
      end
    end

    it "backs up a real (non-symlink) CLAUDE.md instead of overwriting it" do
      Dir.mktmpdir do |home|
        FileUtils.mkdir_p(File.join(home, ".claude"))
        claude_md = File.join(home, ".claude", "CLAUDE.md")
        File.write(claude_md, "a real file the user wrote")

        UpdateHost.link_claude_md(home: home, repo_root: UpdateHost::REPO_ROOT)

        _(File.symlink?(claude_md)).must_equal true
        _(File.read("#{claude_md}.bak")).must_equal "a real file the user wrote"
      end
    end

    it "removes an old ~/.claude/AGENTS.md link to our source, but not anyone else's" do
      Dir.mktmpdir do |home|
        FileUtils.mkdir_p(File.join(home, ".claude"))
        agents_md = File.join(home, ".claude", "AGENTS.md")
        File.symlink(File.join(UpdateHost::REPO_ROOT, "share", "agents-config", "AGENTS.md"), agents_md)

        UpdateHost.link_claude_md(home: home, repo_root: UpdateHost::REPO_ROOT)
        _(File.symlink?(agents_md)).must_equal false

        File.symlink("/somewhere/else/AGENTS.md", agents_md)
        UpdateHost.link_claude_md(home: home, repo_root: UpdateHost::REPO_ROOT)
        _(File.readlink(agents_md)).must_equal "/somewhere/else/AGENTS.md"
      end
    end
  end

  describe "verify_claude_settings" do
    it "is ok when settings.json has every template key" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          FileUtils.cp(claude_template, File.join(config_dir, "settings.json"))

          out = StringIO.new
          v = UpdateHost::Verifier.new(io: out)
          UpdateHost.verify_claude_settings(v, home: config_dir, repo_root: UpdateHost::REPO_ROOT)

          _(v.failed?).must_equal false
          _(out.string).must_include "ok    #{File.join(config_dir, 'settings.json')}"
        end
      end
    end

    it "warns (does not fail or write) when the live file is missing template keys" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          target = File.join(config_dir, "settings.json")
          File.write(target, "{}")

          out = StringIO.new
          v = UpdateHost::Verifier.new(io: out)
          UpdateHost.verify_claude_settings(v, home: config_dir, repo_root: UpdateHost::REPO_ROOT)

          _(v.failed?).must_equal false
          _(out.string).must_include "warn  #{target} is missing keys from"
          _(File.read(target)).must_equal "{}"
        end
      end
    end

    it "warns (does not fail or create it) when settings.json is missing" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          target = File.join(config_dir, "settings.json")

          out = StringIO.new
          v = UpdateHost::Verifier.new(io: out)
          UpdateHost.verify_claude_settings(v, home: config_dir, repo_root: UpdateHost::REPO_ROOT)

          _(v.failed?).must_equal false
          _(out.string).must_include "warn  #{target} missing"
          _(File.exist?(target)).must_equal false
        end
      end
    end

    it "warns (does not fail) on malformed JSON" do
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
          real = File.join(config_dir, "settings.json")
          moved = File.join(config_dir, "settings.actual.json")
          FileUtils.cp(claude_template, moved)
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

  describe "merge_claude_settings" do
    it "adds missing template keys, keeps existing values, and backs up the old file" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          target = File.join(config_dir, "settings.json")
          File.write(target, JSON.generate("model" => "mine"))

          out, = capture_io { UpdateHost.merge_claude_settings(home: config_dir, repo_root: UpdateHost::REPO_ROOT) }

          merged = JSON.parse(File.read(target))
          _(merged["model"]).must_equal "mine"
          _(UpdateHost.deep_merge(JSON.parse(File.read(claude_template)), merged)).must_equal merged
          _(File.read("#{target}.bak")).must_equal JSON.generate("model" => "mine")
          _(out).must_include "merged template keys"
        end
      end
    end

    it "does nothing when every template key is already present" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          target = File.join(config_dir, "settings.json")
          FileUtils.cp(claude_template, target)

          capture_io { UpdateHost.merge_claude_settings(home: config_dir, repo_root: UpdateHost::REPO_ROOT) }

          _(File.exist?("#{target}.bak")).must_equal false
        end
      end
    end

    it "aborts when settings.json is missing" do
      Dir.mktmpdir do |config_dir|
        with_env("CLAUDE_CONFIG_DIR" => config_dir) do
          # Minitest lets SystemExit pass through assert_raises, so rescue it by hand.
          exited = false
          capture_io do
            UpdateHost.merge_claude_settings(home: config_dir, repo_root: UpdateHost::REPO_ROOT)
          rescue SystemExit
            exited = true
        end
        _(exited).must_equal true
        end
      end
    end
  end

  describe "remote_merge_script" do
    it "loads the unpacked script and calls the merge" do
      _(UpdateHost.remote_merge_script).must_include "Applications/scripts/update-host"
      _(UpdateHost.remote_merge_script).must_include "UpdateHost.merge_claude_settings"
    end
  end

  describe "remote_link_script" do
    it "creates links that resolve, including ones nested under ~/.claude and ~/.config" do
      Dir.mktmpdir do |home|
        UpdateHost::CONFIG_FILES.each do |rel|
          FileUtils.mkdir_p(File.join(home, "Applications", "share", rel))
        end

        _(system({ "HOME" => home }, "sh", "-c", UpdateHost.remote_link_script, chdir: home)).must_equal true

        UpdateHost::CONFIG_FILES.each do |rel|
          dotfile = File.join(home, UpdateHost.dest_rel(rel))
          _(File.exist?(dotfile)).must_equal true, "#{dotfile} -> #{File.readlink(dotfile)} is dangling"
        end
      end
    end
  end

  describe "verify_hook_executability" do
    it "reports ok for +x hooks and fail for non-executable ones" do
      Dir.mktmpdir do |repo_root|
        hooks_dir = File.join(repo_root, "share", "agents-config", "hooks")
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

    it "falls back to ~/.claude for the stamp when CLAUDE_CONFIG_DIR is unset" do
      Dir.mktmpdir do |bin_dir|
        fake_claude = File.join(bin_dir, "claude")
        File.write(fake_claude, "#!/usr/bin/env bash\necho '9.9.9 (Claude Code)'\n")
        FileUtils.chmod(0o755, fake_claude)

        Dir.mktmpdir do |home|
          FileUtils.mkdir_p(File.join(home, ".claude"))
          File.write(File.join(home, ".claude", ".claude-code-verified-version"), "9.9.9\n")

          with_env(
            "PATH" => "#{bin_dir}#{File::PATH_SEPARATOR}#{ENV.fetch('PATH', '')}",
            "CLAUDE_CONFIG_DIR" => nil
          ) do
            out = StringIO.new
            v = UpdateHost::Verifier.new(io: out)
            UpdateHost.verify_claude_version(v, home: home)

            _(out.string).must_include "ok    Claude Code 9.9.9 verified against changelog"
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

      UpdateHost.link_claude_md(home: home, repo_root: UpdateHost::REPO_ROOT)
      FileUtils.cp(claude_template, File.join(config_dir, "settings.json"))
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
