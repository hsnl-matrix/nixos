{ config, pkgs, lib, _info, ... }:
let
  cfg = config.presets.zsh;
in
{
  options.presets.zsh = {
    color1 = lib.mkOption {
      type = lib.types.str;
      default = "1";
    };
    color2 = lib.mkOption {
      type = lib.types.str;
      default = "2";
    };
    motd = lib.mkEnableOption "host-specific motd";
  };

  config = {
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;

    environment.loginShellInit = lib.mkIf cfg.motd ''
      if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
        if [ -t 1 ]; then # only on interactive shells
          ${pkgs.proced-motd}/bin/proced-motd ${_info.hostName}
        fi
      fi
    '';

    environment.etc.zshrc.text =
      ''
        export DIRENV_LOG_FORMAT=
        typeset -A key
        key=(
             BackSpace	"''${terminfo[kbs]}"
             Home			 "''${terminfo[khome]}"
             End				"''${terminfo[kend]}"
             Insert		 "''${terminfo[kich1]}"
             Delete		 "''${terminfo[kdch1]}"
             Up				 "''${terminfo[kcuu1]}"
             Down			 "''${terminfo[kcud1]}"
             Left			 "''${terminfo[kcub1]}"
             Right			"''${terminfo[kcuf1]}"
             PageUp		 "''${terminfo[kpp]}"
             PageDown	 "''${terminfo[knp]}"
        )

        function bind2maps () {
             local i sequence widget
             local -a maps

             while [[ "''$1" != "--" ]]; do
                 maps+=( "''$1" )
                 shift
             done
             shift

             sequence="''${key[''$1]}"
             widget="''$2"

             [[ -z "''$sequence" ]] && return 1

             for i in "''${maps[@]}"; do
                 bindkey -M "''$i" "''$sequence" "''$widget"
             done
        }

        bind2maps emacs						 -- BackSpace	 backward-delete-char
        bind2maps			 viins			 -- BackSpace	 vi-backward-delete-char
        bind2maps						 vicmd -- BackSpace	 vi-backward-char
        bind2maps emacs						 -- Home				beginning-of-line
        bind2maps			 viins vicmd -- Home				vi-beginning-of-line
        bind2maps emacs						 -- End				 end-of-line
        bind2maps			 viins vicmd -- End				 vi-end-of-line
        bind2maps emacs viins			 -- Insert			overwrite-mode
        bind2maps						 vicmd -- Insert			vi-insert
        bind2maps emacs						 -- Delete			delete-char
        bind2maps			 viins vicmd -- Delete			vi-delete-char
        bind2maps emacs viins vicmd -- Up					up-line-or-history
        bind2maps emacs viins vicmd -- Down				down-line-or-history
        bind2maps emacs						 -- Left				backward-char
        bind2maps			 viins vicmd -- Left				vi-backward-char
        bind2maps emacs						 -- Right			 forward-char
        bind2maps			 viins vicmd -- Right			 vi-forward-char

        # Make sure the terminal is in application mode, when zle is
        # active. Only then are the values from ''$terminfo valid.
        if (( ''${+terminfo[smkx]} )) && (( ''${+terminfo[rmkx]} )); then
             function zle-line-init () {
                 emulate -L zsh
                 printf '%s' ''${terminfo[smkx]}
             }
             function zle-line-finish () {
                 emulate -L zsh
                 printf '%s' ''${terminfo[rmkx]}
             }
             zle -N zle-line-init
             zle -N zle-line-finish
        else
             for i in {s,r}mkx; do
                 (( ''${+terminfo[''$i]} )) || debian_missing_features+=(''$i)
             done
             unset i
        fi

        unfunction bind2maps

        export EDITOR=nvim
        export FORCE_COLOR=2
        LANG=en_US.utf8

        alias vim=nvim
        alias ls=eza --group-directories-first --color=always
        alias l=eza --group-directories-first --color=always -l -a --git
        alias git-sha256=git ls-remote origin | sed -n "\,\t$ref, { s,\(.*\)\t\(.*\),\1,; p; q}"

        # keys
        typeset -A key
        key[Delete]=''${terminfo[kdch1]}
        [[ -n "''${key[Delete]}"	 ]]	&& bindkey	"''${key[Delete]}"	 delete-char
        [[ -n "''$key[Up]"	 ]] && bindkey -- "''$key[Up]"	 up-line-or-beginning-search
        [[ -n "''$key[Down]" ]] && bindkey -- "''$key[Down]" down-line-or-beginning-search
        bindkey "''${terminfo[kpp]}" up-line-or-history			 # [PageUp] - Up a line of history
        bindkey "''${terminfo[knp]}" down-line-or-history		 # [PageDown] - Down a line of history
        bindkey "''${terminfo[khome]}" beginning-of-line			# [Home] - Go to beginning of line
        bindkey "''${terminfo[kend]}"	end-of-line						# [End] - Go to end of line
        bindkey '^[[1;5C' forward-word												# [Ctrl-RightArrow] - move forward one word
        bindkey '^[[1;5D' backward-word											 # [Ctrl-LeftArrow] - move backward one word

        # completion
        autoload -Uz compinit
        compinit -d "''${HOME}/.zcompdump-''${ZSH_VERSION}"
        zstyle ':completion:*' list-dirs-first true
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' list-colors "''$LS_COLORS"
        zstyle ':completion:*' menu select auto
        zstyle ':completion::complete:*' cache-path "''${HOME}/.cache/zcompcache"
        zstyle ':completion::complete:*' use-cache 1
        zstyle ':completion::complete:*' gain-privileges 1
        zstyle ':completion:*' rehash true

        #history
        HISTFILE=~/.zsh_history
        SAVEHIST=100000
        HISTSIZE=100000
        autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search

        setopt append_history
        setopt extended_history
        setopt hist_expire_dups_first
        setopt hist_ignore_dups
        setopt hist_ignore_space
        setopt hist_verify
        setopt inc_append_history
        setopt share_history
        setopt prompt_subst

        function git_branch() {
          branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {print $NF}')
          if [[ $branch == "" ]];
          then
            :
          else
            echo '%F{3} '$branch'''
          fi
        }

        nix_shell() {
          if [[ -n "$IN_NIX_SHELL" ]]; then
            echo '%F{2} nix-shell'
          fi
        }

        # prompt
        PROMPT='%F{${cfg.color1}}[%m] %F{${cfg.color2}}%n [%3c$(git_branch)$(nix_shell)%F{${cfg.color2}}] %f'
      '';
  };
}
