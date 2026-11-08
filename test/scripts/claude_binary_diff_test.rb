require "test_helper"

load File.expand_path("../../scripts/claude-binary-diff", __dir__)

describe :claude_binary_diff do
  OLD_BIN = <<~JS.b
    foo:()=>O().optional().describe('Enable foo.'),bar:()=>N().describe("Bar count.")
    i.CLAUDE_CODE_OLD_FLAG;i.ANTHROPIC_API_KEY;theme
  JS
  NEW_BIN = <<~JS.b
    foo:()=>O().optional().describe('Enable foo. Deprecated.'),baz:()=>O().describe(`New baz.`)
    i.CLAUDE_CODE_NEW_FLAG;i.ANTHROPIC_API_KEY;theme
  JS

  it "lists added and removed env vars, ignoring unchanged ones" do
    out = report(OLD_BIN, NEW_BIN, [])
    _(out).must_include "== env vars (CLAUDE_*/ANTHROPIC_*): +1 -1"
    _(out).must_include "+ CLAUDE_CODE_NEW_FLAG"
    _(out).must_include "- CLAUDE_CODE_OLD_FLAG"
    _(out).wont_include "ANTHROPIC_API_KEY"
  end

  it "lists added, removed and re-described schema keys" do
    out = report(OLD_BIN, NEW_BIN, [])
    _(out).must_include "+1 -1 ~1"
    _(out).must_include "+ baz: New baz."
    _(out).must_include "- bar"
    _(out).must_include "~ foo (old): Enable foo."
    _(out).must_include "~ foo (new): Enable foo. Deprecated."
  end

  it "flags only our keys absent from the new binary" do
    out = report(OLD_BIN, NEW_BIN, %w[theme bar])
    _(out).must_include "our settings keys missing from new binary: 1 of 2"
    _(out).must_include "! bar"
    _(out).wont_include "! theme"
  end

  it "collects nested settings keys but not names inside opaque maps" do
    keys = settings_keys(
      "$schema" => "x",
      "attribution" => { "commit" => "" },
      "modelSettings" => { "claude-opus-5-5" => { "effortLevel" => "high" } },
      "permissions" => { "allow" => ["Bash(ls *)"] }
    )
    _(keys).must_equal %w[attribution commit modelSettings permissions allow]
  end
end
