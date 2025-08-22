class GwOrchestrator < Formula
  desc "AI-powered Git worktree and tmux session manager with modern TUI"
  homepage "https://github.com/adeperio/orchestra"
  version "0.1.0"
  license "Proprietary"

  # Binary-only distribution - downloads pre-compiled packages
  if OS.mac? && Hardware::CPU.intel?
    url "https://github.com/adeperio/orchestra/releases/download/v0.1.0/gw-orchestrator-macos-intel.tar.gz"
    sha256 "ab1dc6c2ef094ac3f82539430962e9a381edbaa1fde9155c13d8edc0ef2c229d"
  elsif OS.mac? && Hardware::CPU.arm?
    url "https://github.com/adeperio/orchestra/releases/download/v0.1.0/gw-orchestrator-macos-arm64.tar.gz"
    sha256 "9d7710bc9214935e6286c0462ea661ceaa4f33c45218f3a32a6823c2710522a8"
  elsif OS.linux? && Hardware::CPU.intel?
    url "https://github.com/adeperio/orchestra/releases/download/v0.1.0/gw-orchestrator-linux-x64.tar.gz"
    sha256 "PLACEHOLDER_SHA256_LINUX"
  else
    odie "Orchestra is not available for #{OS.kernel_name} #{Hardware::CPU.arch}"
  end

  depends_on "git"
  depends_on "tmux" => :recommended
  depends_on "jq"

  def install
    # Install pre-compiled binary (renamed from gw-tui in the package)
    bin.install "gw-orchestrator"
    
    # Install runtime scripts to libexec
    libexec.install "gwr.sh"
    libexec.install "gw.sh"
    libexec.install "gw-bridge.sh"
    libexec.install "commands.sh"
    
    # Install API scripts
    (libexec/"api").mkpath
    (libexec/"api").install "api/git.sh"
    (libexec/"api").install "api/tmux.sh"
    
    # Create wrapper scripts that set correct paths
    (bin/"gwr").write wrapper_script("gwr.sh")
    (bin/"gw").write wrapper_script("gw.sh")
  end

  def wrapper_script(script_name)
    <<~EOS
      #!/bin/bash
      export GW_ORCHESTRATOR_ROOT="#{libexec}"
      export GW_TUI_BIN="#{bin}/gw-orchestrator"
      exec "#{libexec}/#{script_name}" "$@"
    EOS
  end

  def caveats
    <<~EOS
      To enable directory switching, add these functions to your shell profile:

      For bash (~/.bashrc):
        gwr() {
          local out="$(command gwr "$@")"
          local status=$?
          local cd_line="$(echo "$out" | grep -m1 '^cd')"
          [[ -n $cd_line ]] && eval "$cd_line"
          echo "$out" | grep -v '^cd'
          return $status
        }

        gw() {
          local out="$(command gw "$@")"
          local status=$?
          local cd_line="$(echo "$out" | grep -m1 '^cd')"
          [[ -n $cd_line ]] && eval "$cd_line"
          echo "$out" | grep -v '^cd'
          return $status
        }

      For zsh (~/.zshrc):
        gwr() {
          local out="$(command gwr "$@")"
          local status=$?
          local cd_line="$(echo "$out" | grep -m1 '^cd')"
          [[ -n $cd_line ]] && eval "$cd_line"
          echo "$out" | grep -v '^cd'
          return $status
        }

        gw() {
          local out="$(command gw "$@")"
          local status=$?
          local cd_line="$(echo "$out" | grep -m1 '^cd')"
          [[ -n $cd_line ]] && eval "$cd_line"
          echo "$out" | grep -v '^cd'
          return $status
        }

      Then restart your shell or run:
        source ~/.bashrc  # or source ~/.zshrc

      For AI-powered session naming, set your ANTHROPIC_API_KEY:
        export ANTHROPIC_API_KEY="your-api-key"
    EOS
  end

  test do
    # Test that the binary exists and is executable
    assert_predicate bin/"gw-orchestrator", :exist?
    assert_predicate bin/"gw-orchestrator", :executable?
    
    # Test that wrapper scripts are accessible
    assert_predicate bin/"gwr", :exist?
    assert_predicate bin/"gw", :exist?
    
    # Test basic help output (in a safe way)
    output = shell_output("#{bin}/gw help 2>&1", 0)
    assert_match(/Usage|Commands|Options/, output)
  end
end