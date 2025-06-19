{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # GNU Compiler Collection
    gcc
  ];
}
