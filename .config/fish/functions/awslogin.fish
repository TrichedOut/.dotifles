function awslogin
  aws sso login
  set IFS '\n'
  for cred in (aws configure export-credentials --format env --profile default)
    set field $(echo $cred | cut -d '=' -f 1 | cut -d ' ' -f 2)
    set value $(echo $cred | cut -d '=' -f 2)
    set -gx $field $value
  end;
end
