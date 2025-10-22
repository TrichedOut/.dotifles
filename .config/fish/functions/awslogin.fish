function awslogin --description "login to and export credentials for aws"
  aws sso login
  eval "$(aws configure export-credentials --format env)"
end
