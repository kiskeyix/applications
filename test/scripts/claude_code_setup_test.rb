require "test_helper"
require "tmpdir"

load File.expand_path("../../scripts/claude-code-setup", __dir__)

describe :claude_code_setup do
  def platform_as(family)
    p = Platform.allocate
    p.instance_variable_set(:@family, family)
    p
  end

  describe "Platform command builders" do
    it "builds macos commands via brew, never sudo" do
      p = platform_as(:macos)
      _(p.pkg_update_cmd).must_equal "brew update"
      _(p.pkg_install_cmd(%w[git curl])).must_equal "brew install git curl"
      _(p.pkg_remove_cmd(%w[git])).must_equal "brew uninstall git"
      _(p.pkg_autoremove_cmd).must_equal "brew autoremove"
      _(p.epel_needed?).must_equal false
    end

    it "builds debian commands via apt-get, honoring no_recommends" do
      p = platform_as(:debian)
      _(p.pkg_update_cmd).must_match(/apt-get .*update/)
      _(p.pkg_install_cmd(%w[git])).must_equal(
        "DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 install -y git"
      )
      _(p.pkg_install_cmd(%w[git], no_recommends: true)).must_equal(
        "DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 install -y --no-install-recommends git"
      )
      _(p.pkg_remove_cmd(%w[git])).must_equal "apt-get remove -y --purge git"
      _(p.epel_needed?).must_equal false
    end

    it "builds rhel commands via dnf and requires EPEL" do
      p = platform_as(:rhel)
      _(p.pkg_update_cmd).must_match(/dnf check-update/)
      _(p.pkg_install_cmd(%w[git])).must_equal "dnf install -y git"
      _(p.pkg_remove_cmd(%w[git])).must_equal "dnf remove -y git"
      _(p.pkg_autoremove_cmd).must_equal "dnf autoremove -y"
      _(p.epel_needed?).must_equal true
    end
  end

  describe "Platform#detect" do
    # Redefines File.exist?/File.read for the one path Platform#detect checks,
    # falling through to the real implementation for everything else, then
    # restores the originals. (No minitest/mock dependency: minitest 6 moved
    # Object#stub into a separate gem this repo doesn't otherwise need.)
    def detect_with(os_release_content)
      original_exist = File.method(:exist?)
      original_read = File.method(:read)
      target = "/etc/os-release"

      File.define_singleton_method(:exist?) do |*args|
        args.first == target ? !os_release_content.nil? : original_exist.call(*args)
      end
      File.define_singleton_method(:read) do |*args|
        args.first == target ? os_release_content : original_read.call(*args)
      end

      Platform.new.send(:detect)
    ensure
      File.define_singleton_method(:exist?, original_exist)
      File.define_singleton_method(:read, original_read)
    end

    it "recognizes debian-family via ID" do
      id, family, = detect_with(%(ID=ubuntu\nID_LIKE=debian\nVERSION_ID="24.04"\n))
      _(family).must_equal :debian
      _(id).must_equal "ubuntu"
    end

    it "recognizes rhel-family via ID" do
      _, family, = detect_with(%(ID=rocky\nVERSION_ID="9.3"\n))
      _(family).must_equal :rhel
    end

    it "recognizes rhel-family via ID_LIKE" do
      _, family, = detect_with(%(ID=amzn\nID_LIKE="rhel fedora"\n))
      _(family).must_equal :rhel
    end

    it "falls back to unknown for an unrecognized distro" do
      _, family, = detect_with(%(ID=gentoo\n))
      _(family).must_equal :unknown
    end

    it "falls back to unknown when os-release is missing" do
      _, family, = detect_with(nil)
      _(family).must_equal :unknown
    end

    it "recognizes macos via RUBY_PLATFORM" do
      original = RUBY_PLATFORM
      Object.send(:remove_const, :RUBY_PLATFORM)
      Object.const_set(:RUBY_PLATFORM, "arm64-darwin23")
      _, family, = Platform.new.send(:detect)
      _(family).must_equal :macos
    ensure
      Object.send(:remove_const, :RUBY_PLATFORM)
      Object.const_set(:RUBY_PLATFORM, original)
    end
  end

  describe "ClaudeSetup#deep_merge" do
    it "lets existing scalar keys win over the base" do
      setup = ClaudeSetup.new(platform_as(:debian))
      merged = setup.send(:deep_merge, { "a" => 1, "b" => 2 }, { "a" => 99 })
      _(merged).must_equal({ "a" => 99, "b" => 2 })
    end

    it "recurses into nested hashes" do
      setup = ClaudeSetup.new(platform_as(:debian))
      base = { "hooks" => { "Stop" => "default", "Start" => "default" } }
      override = { "hooks" => { "Stop" => "custom" } }
      merged = setup.send(:deep_merge, base, override)
      _(merged).must_equal({ "hooks" => { "Stop" => "custom", "Start" => "default" } })
    end

    it "replaces arrays wholesale instead of unioning them" do
      # Unlike UpdateHost.deep_merge (which unions arrays with de-duplication),
      # this deep_merge treats a non-Hash override as an outright replacement.
      setup = ClaudeSetup.new(platform_as(:debian))
      merged = setup.send(:deep_merge, { "allow" => %w[a b] }, { "allow" => %w[c] })
      _(merged).must_equal({ "allow" => ["c"] })
    end
  end
end
