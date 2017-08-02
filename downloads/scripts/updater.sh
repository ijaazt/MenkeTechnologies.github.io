#!/usr/bin/env bash
#{{{                    MARK:Header
#**************************************************************
#####   Author: JACOBMENKE
#####   Date: Mon Jul 10 12:03:45 EDT 2017
#####   Purpose: bash  script to update all command line packages locally and on servers 
#####   Notes:
#}}}***********************************************************
# clear screen
clear

prettyPrint(){
    printf "\e[1;4m"
    printf "$1"
    printf "\n\e[0m"
}

exists(){
    type "$1" >/dev/null 2>&1
}

#start white text on blue background \e44:37m, -e required for escape sequences
#echo -e "\e[44;37m"
bash "$SCRIPTS/printHeader.sh"

prettyPrint "Updating Python Dependencies"
#pip lists outdated programs and get first column with awk
#store in outdated

exists pip3 && {
outdated=$(pip3 list --outdated | awk '{print $1}')

#install outdated pip modules 
#split on space
for i in $outdated; do
    pip3 install --upgrade "$i" #&> /dev/null
done

#update pip itself
pip3 install --upgrade pip setuptools wheel &> /dev/null

}

exists rvm && {
prettyPrint "Updating Ruby Dependencies"
rvm get stable
gem update --system
gem update
gem cleanup
rvm cleanup all
}

exists brew && {
    prettyPrint "Updating Homebrew Dependencies"
    brew update #&> /dev/null
    brew upgrade #&> /dev/null
    #remove brew cache
    rm -rf "$(brew --cache)"
    #removing old symbolic links
    brew prune
    #remote old programs occupying disk sectors
    brew cleanup
    brew cask cleanup
    #check is we have brew cu
    brew cu 1>/dev/null 2>&1 && {
        # we have brew cu
        prettyPrint "Updating Homebrew Casks!"
        brew cu --all -y --cleanup
     } || {
        # we don't have brew cu
        prettyPrint "Installing brew-cask-upgrade"
        brew tap buo/cask-upgrade
        brew update
        prettyPrint "Updating Homebrew Casks!"
        brew cu --all -y --cleanup
     } 
}

exists npm && {
prettyPrint "Updating NPM Dependencies"
for package in $(npm -g outdated --parseable --depth=0 | cut -d: -f4)
do
    npm install -g "$package"
done
#updating npm itself
npm i -g npm
}

exists yarn && {
prettyPrint "Updating yarn modules"
yarn global upgrade
}

exists cpanm && {

prettyPrint "Updating Perl Dependencies"
perlOutdated=$(cpan-outdated -p)

if [[ ! -z "$perlOutdated" ]]; then
    echo "$perlOutdated" | cpanm --force 2> /dev/null
fi
}

gitRepoUpdater(){
    enclosing_dir="$1"

    if [[ -d "$enclosing_dir" ]]; then

        for generic_git_repo_plugin in "$enclosing_dir/"*; do
            if [[ -d "$generic_git_repo_plugin" ]]; then
                if [[ -d "$generic_git_repo_plugin"/.git ]]; then
                    printf "%s: " "$(basename "$generic_git_repo_plugin")"
                    git -C "$generic_git_repo_plugin" pull
                fi
            fi
        done
    fi
}

prettyPrint "Updating Tmux Plugins"
gitRepoUpdater "$HOME/.tmux/plugins"

prettyPrint "Updating Pathogen Plugins"
#update pathogen plugins
gitRepoUpdater "$HOME/.vim/bundle"

prettyPrint "Updating OhMyZsh"
cd "$HOME/.oh-my-zsh/tools" && bash "$HOME/.oh-my-zsh/tools/upgrade.sh"

prettyPrint "Updating OhMyZsh Plugins"
gitRepoUpdater "$HOME/.oh-my-zsh/custom/plugins"

prettyPrint "Updating OhMyZsh Themes"
gitRepoUpdater "$HOME/.oh-my-zsh/custom/themes"

prettyPrint "Updating Tmux Plugins"
gitRepoUpdater "$HOME/.tmux/plugins"

#first argument is user@host and port number configured in .ssh/config
updatePI(){
    #-t to force pseudoterminal allocation for interactive programs on remote host
    #pipe yes into programs that require confirmation
    #alternatively apt-get has -y option
    #semicolon to chain commands
    # -x option to disable x11 forwarding
    ssh -x "$1" 'yes | sudo apt-get update
    yes | sudo apt-get dist-upgrade
    yes | sudo apt-get autoremove
    yes | sudo apt-get upgrade'

    #here we will update the Pi's own software and vim plugins (not included in apt-get)
    #avoid sending commmands from stdin into ssh, better to use string after ssh
    ssh -x "$1" "$(< $SCRIPTS/rpiSoftwareUpdater.sh)"
}

arrayOfPI=(r r2)

#for loop through arrayOfPI, each item in array is item is .ssh/config file
for pi in "${arrayOfPI[@]}"; do
    updatePI "$pi"
done

prettyPrint "Updating Vundle Plugins"
vim -c VundleUpdate -c quitall

#decolorize prompt
echo -e "Done\e[0m"
clear
