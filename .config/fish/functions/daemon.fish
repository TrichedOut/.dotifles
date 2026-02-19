function daemon --description 'run a program as a daemon'
  setsid $argv[1] >/dev/null 2>&1 </dev/null &
end
