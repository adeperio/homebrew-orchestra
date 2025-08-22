class Orchestra < Formula
  desc "AI-powered Git worktree and tmux session manager with modern TUI"
  homepage "https://github.com/humanunsupervised/orchestra"
  version "0.1.4"
  license "Proprietary"

  # Binary-only distribution - downloads pre-compiled packages
  if OS.mac? && Hardware::CPU.intel?
    url "https://github.com/humanunsupervised/orchestra/releases/download/v0.1.4/orchestra-macos-intel.tar.gz"
    sha256 "7abef9873a54f3e5df45369111a62911db6187612f937d34f01181c5bb731630"
  elsif OS.mac? && Hardware::CPU.arm?
    url "https://github.com/humanunsupervised/orchestra/releases/download/v0.1.4/orchestra-macos-arm64.tar.gz"
    sha256 "53ff34bacbfda15ed12c1910c67fa1657053104f2677bfbe843340b6f257a0ad"
  elsif OS.linux? && Hardware::CPU.intel?
    url "https://github.com/humanunsupervised/orchestra/releases/download/v0.1.4/orchestra-linux-x64.tar.gz"
    sha256 "PLACEHOLDER_SHA256_LINUX"
  else
    odie "Orchestra is not available for #{OS.kernel_name} #{Hardware::CPU.arch}"
  end

  depends_on "git"
  depends_on "tmux" => :recommended
  depends_on "jq"

  def install
    # Install pre-compiled binary (renamed from gw-tui in the package)
    bin.install "orchestra" => "orchestra-bin"
    
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
    
    # Create primary orchestra command (same as gwr for TUI interface)
    (bin/"orchestra").write orchestra_wrapper_script()
  end

  def wrapper_script(script_name)
    <<~EOS
      #!/bin/bash
      export GW_ORCHESTRATOR_ROOT="#{libexec}"
      export GW_TUI_BIN="#{bin}/orchestra-bin"
      exec "#{libexec}/#{script_name}" "$@"
    EOS
  end

  def orchestra_wrapper_script
    <<~EOS
      #!/bin/bash
      # Primary Orchestra command - launches TUI interface
      export GW_ORCHESTRATOR_ROOT="#{libexec}"
      export GW_TUI_BIN="#{bin}/orchestra-bin"
      
      # Handle directory switching like gwr wrapper
      out="$(#{libexec}/gwr.sh "$@")"
      status=$?
      cd_line="$(echo "$out" | grep -m1 '^cd')"
      [[ -n $cd_line ]] && eval "$cd_line"
      echo "$out" | grep -v '^cd'
      exit $status
    EOS
  end

  def caveats
    <<~EOS
      🎵 Orchestra is ready to use! 

      Primary command:
        orchestra       # Launch AI-powered TUI interface
        
      Alternative commands (for existing users):
        gwr            # Same as orchestra (TUI interface)  
        gw ls          # CLI worktree operations

      The 'orchestra' command includes automatic directory switching.
      
      For advanced usage, you can also set up shell functions for gwr/gw:

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

      For AI-powered session naming, set your ANTHROPIC_API_KEY:
        export ANTHROPIC_API_KEY="your-api-key"
    EOS
  end

  test do
    # Test that the binary exists and is executable
    assert_predicate bin/"orchestra-bin", :exist?
    assert_predicate bin/"orchestra-bin", :executable?
    
    # Test that wrapper scripts are accessible
    assert_predicate bin/"orchestra", :exist?
    assert_predicate bin/"gwr", :exist?
    assert_predicate bin/"gw", :exist?
    
    # Test basic help output (in a safe way)
    output = shell_output("#{bin}/gw help 2>&1", 0)
    assert_match(/Usage|Commands|Options/, output)
  end
end