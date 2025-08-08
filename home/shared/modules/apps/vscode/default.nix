{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nyx.modules.apps.vscode;
in
{
  options.nyx.modules.apps.vscode = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure vscode";
    };
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      # disallow extensions being installed or updated by vscode
      mutableExtensionsDir = false;
      profiles.default = {
        userSettings = {
          "editor.insertSpaces" = true;
          "editor.tabSize" = 2;
          "editor.autoIndent" = "advanced";
          "diffEditor.ignoreTrimWhitespace" = false;
          "editor.detectIndentation" = false;
          "extensions.autoUpdate" = false;
          "window.zoomLevel" = 1;
          "eslint.codeActionsOnSave.rules" = null;
          "editor.fontLigatures" = false;
          "terminal.integrated.fontFamily" = "MesloLGS Nerd Font Mono";
          "editor.fontFamily" = "MesloLGS Nerd Font Mono; Monaco; 'Courier New'; monospace";
          "update.mode" = "manual";
          "telemetry.telemetryLevel" = "off";
          "files.autoSave" = "afterDelay";
          "terminal.integrated.macOptionIsMeta" = true;
          "application.shellEnvironmentResolutionTimeout" = 30;
        };
        extensions = with pkgs.vscode-marketplace; [
          # https://raw.githubusercontent.com/nix-community/nix-vscode-extensions/master/data/cache/vscode-marketplace-latest.json
          dbaeumer.vscode-eslint
          formulahendry.code-runner
          ritwickdey.liveserver
        ];
        # ++ (with pkgs.open-vsx; [
        # # https://raw.githubusercontent.com/nix-community/nix-vscode-extensions/master/data/cache/open-vsx-latest.json
        # ]);
        # ++ (with pkgs.vscode-extensions; [
        #       ms-azuretools.vscode-docker
        #     ]);
        keybindings = [
          {
            "key" = "ctrl+`";
            "command" = "workbench.action.terminal.focus";
            "when" = "editorTextFocus";
          }
          {
            "key" = "ctrl+`";
            "command" = "workbench.action.focusActiveEditorGroup";
            "when" = "terminalFocus";
          }
          {
            "key" = "ctrl+'";
            "command" = "workbench.action.terminal.toggleTerminal";
          }
        ];
        enableExtensionUpdateCheck = true;
        enableUpdateCheck = true;
      };
    };
  };
}
