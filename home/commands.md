nix-collect-garbage

To remove ALL old generations, remember to run the command again with `sudo`

```
nixos-rebuild list-generations # list existing generations
nix-collect-garbage -d # Delete all user generations.
sudo nix-collect-garbage -d # Delete all system generations.
sudo /run/current-system/bin/switch-to-configuration boot # clear the boot menu
```
