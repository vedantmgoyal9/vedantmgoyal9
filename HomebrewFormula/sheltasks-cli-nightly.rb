# typed: false
# frozen_string_literal: true

# This file was generated by GoReleaser. DO NOT EDIT.
class SheltasksCliNightly < Formula
  desc "Sheltasks (Nightly): My CLI friend helping me with my daily tasks"
  homepage "https://github.com/vedantmgoyal9/vedantmgoyal9"
  version "1.1.0-nightly"
  license "MIT"

  depends_on "msitools"

  on_macos do
    on_arm do
      url "https://github.com/vedantmgoyal9/vedantmgoyal9/releases/download/sheltasks-cli/nightly/sheltasks-cli_darwin_arm64.tar.gz"
      sha256 "0714097e9d4dc49b878b740ac684d42b307ab64ad922e8b765b2ede0059fc79e"

      def install
        bin.install "sheltasks-cli"
      end
    end
  end

  on_linux do
    on_intel do
      if Hardware::CPU.is_64_bit?
        url "https://github.com/vedantmgoyal9/vedantmgoyal9/releases/download/sheltasks-cli/nightly/sheltasks-cli_linux_amd64.tar.gz"
        sha256 "2b1cc3daa835a8ca19cb2db90d4af176005658c12447a14947b769f6e98262a5"

        def install
          bin.install "sheltasks-cli"
        end
      end
    end
    on_arm do
      if Hardware::CPU.is_64_bit?
        url "https://github.com/vedantmgoyal9/vedantmgoyal9/releases/download/sheltasks-cli/nightly/sheltasks-cli_linux_arm64.tar.gz"
        sha256 "f9f326017d2d2b695bf70a8d0a030a840ac593e5a959b74b7a83f61d70ec4516"

        def install
          bin.install "sheltasks-cli"
        end
      end
    end
  end

  conflicts_with "sheltasks-cli"
end
