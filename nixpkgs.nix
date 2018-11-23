{ rev ? "aeb470b626d391bcb206a568d68065326a512884" }:

builtins.fetchTarball {
  url = "https://github.com/kitecomputing/nixpkgs/archive/${rev}.tar.gz";
  sha256 = "835d1a0b0cd2862ea262ca0df25279ae7e8d8b6a1391a500af8b857b006b4bae";
}
