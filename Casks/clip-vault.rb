cask "clip-vault" do
  version "1.0.0"
  sha256 "b219b14f3df052ddf6768f99601a03c2981efcd010c60e4d17025e6b94e168a0"

  url "https://github.com/nileshchakraborty/clip-vault/releases/download/v#{version}/ClipVault-#{version}.dmg"
  name "ClipVault"
  desc "Lightweight, privacy-first, RAM-only clipboard history manager"
  homepage "https://github.com/nileshchakraborty/clip-vault"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "ClipVault.app"

  postflight_steps do
    run "/usr/bin/xattr", args: ["-d", "com.apple.quarantine", "{{appdir}}/ClipVault.app"], must_succeed: false
  end

  zap trash: [
    "~/Library/Application Support/com.clipvault.mac",
    "~/Library/Preferences/com.clipvault.mac.plist",
    "~/Library/Application Support/Maccy",
    "~/Library/Preferences/org.p0deje.Maccy.plist",
  ]
end
