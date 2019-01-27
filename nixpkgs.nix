{ rev ? "fe634d27d6988d78ade613786fa6082a2fde0254" }:

builtins.fetchTarball {
  url = "https://github.com/intrustd/nixpkgs/archive/${rev}.tar.gz";
  sha256 = "835d1a0b0cd2862ea262ca0df25279ae7e8d8b6a1391a500af8b857b006b4bab";
}
