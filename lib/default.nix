{ inputs, ... }:
{
  module = import ./module { inherit inputs; };
}
