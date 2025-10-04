venv() {
  if [ -d .venv ]; then
    source .venv/bin/activate
  else
    python3 -m venv .venv
    source .venv/bin/activate
  fi
}

alias moi="chezmoi apply"
alias j="just"
alias jr="just run"
alias jd="just debug"
