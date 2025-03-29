{ pkgs, ... }:
{
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
      # ++ (with pkgs.open-vsx; [
      # https://raw.githubusercontent.com/nix-community/nix-vscode-extensions/master/data/cache/open-vsx-latest.json
      # ]);
      extensions = with pkgs.vscode-marketplace; [
        # https://raw.githubusercontent.com/nix-community/nix-vscode-extensions/master/data/cache/vscode-marketplace-latest.json
        dbaeumer.vscode-eslint
        formulahendry.code-runner
        ritwickdey.liveserver
      ];
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
}
