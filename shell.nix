with import <nixpkgs> {};
  mkShell {
    packages = [nodejs pnpm];
  }
