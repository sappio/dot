#!/usr/bin/env bash

# Define some color for colored output
white='\e[0;37m' # White
green='\e[0;32m' # Green
green_bold='\e[1;32m' # Green Bold
red='\e[0;31m' # Red
yellow='\e[0;33m' # Yellow
blue='\e[1;34m' # Blue
coloroff='\e[0m'  # Text Reset

# TODO: appname argument for automations
while getopts ":a:n:t:" opt; do
  case $opt in
    a) app_name="$OPTARG"
    ;;
    n) namespace="$OPTARG"
    ;;
    t) app_type="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1;
    ;;
  esac
done

echo "Installing StartApp required files and dirs ..."
echo ""

skip_git_instructions=0

dot_files_repo="https://github.com/StartappTemplates/dot_openshift.git"

INSTALL_TMP_DIR=/tmp/dot_openshift

rm -rf $INSTALL_TMP_DIR
mkdir -p $INSTALL_TMP_DIR

case $app_type in
  rails) dot_files_repo="https://github.com/StartappTemplates/dot_openshift_rails.git"
  ;;
  *)
  ;;
esac

git clone $dot_files_repo $INSTALL_TMP_DIR

rm -rf .openshift

cp -R $INSTALL_TMP_DIR/.openshift .
chmod +x .openshift/action_hooks/*

app_arguments=""
if [ -n "$app_name" ]; then
  app_arguments="-a $app_name"

  if [ -n "$namespace" ]; then
    app_arguments="$app_arguments -n $namespace"
  fi

  startapp_git_url=""
  the_app=$(app show $app_arguments)

  if [ $? -ne 0 ]; then
      echo ""
      printf "${red}$the_app${coloroff}"
      echo ""
      echo "Try specify namespace with: -n <namespace>"
      exit 1;
  else
    startapp_git_url=$(echo "$the_app"|grep 'Git URL'| awk '{print $3}')

    if [ ! -d ".git" ]; then
      echo ""
      printf "${red}No Git repo here!${coloroff}"
      echo ""
      echo "Initialize new Git repo and run this command again!"
      exit 1;
    else
      echo ""
      echo "Adding required files to git repo"
      echo ""
      git add .openshift
      git commit -m 'Add StartApp required files and dirs'

      echo ""
      echo "Adding startapp remote into your Git repo"
      echo ""
      git remote add startapp $startapp_git_url
      skip_git_instructions=1
    fi
  fi
fi

read -d '' message_without_specify_app <<EOF

`printf "${green_bold}StartApp required files and dirs are here! Sooo....${coloroff}"`

`printf "${blue}What's next?${coloroff}"`
`printf "${blue}------------${coloroff}"`

`printf "${yellow}1. Add StartApp required files and dirs to Git${coloroff}"`

  git add .openshift
  git commit -m 'Add StartApp required files and dirs'


`printf "${yellow}2. Add Git remote to you new StartApp Application${coloroff}"`

  app show -a <your-app-name>
  git remote add startapp ssh://<your-app-repo>.sapp.io....git/

`printf "${yellow}3. Deploy to StartApp servers${coloroff}"`

  git push startapp master -f

`printf "${green}That's all!${coloroff}"`

EOF

read -d '' message_with_app_specified <<EOF


`printf "${green_bold}StartApp required files and dirs are here! Sooo....${coloroff}"`

`printf "${blue}What's next?${coloroff}"`
`printf "${blue}------------${coloroff}"`

`printf "${yellow}Deploy to StartApp servers${coloroff}"`

  git push startapp master -f

`printf "${green}That's all!${coloroff}"`

EOF

if [ $skip_git_instructions -eq 0 ]; then
  echo "$message_without_specify_app"
else
  echo "$message_with_app_specified"
fi

