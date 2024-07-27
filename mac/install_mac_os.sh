#!/usr/bin/env bash
#
#run the following to start the script
#bash ./install_mac_os.sh
bold=$(tput bold)
normal=$(tput sgr0)

if [[ "$OSTYPE" != "darwin"* ]]; then

    echo 'Installation skipped: current platform is not Mac OSX'
    exit 1
fi

echo 'Platform: Mac OSX'
DOTFILES=$(cd $(dirname "${BASH_SOURCE[0]}") && cd .. && pwd)

rm -rf $HOME/.config/kitty
ln -s $DOTFILES/mac/kitty $HOME/.config/kitty
echo 'SimLink created: Kitty'

rm -rf $HOME/.config/nvim
ln -s $DOTFILES/common/nvim $HOME/.config/nvim
echo 'SimLink created: Nvim'

rm -rf $HOME/.config/lvim
ln -s $DOTFILES/common/lvim $HOME/.config/lvim
echo 'SimLink created: Lvim'

rm -rf $HOME/.zshrc
ln -s $DOTFILES/mac/ohMyZsh/.zshrc $HOME/.zshrc
echo 'SimLink created: Oh My Zsh'
echo "${bold}To install the spaceship promt for Oh My Zsh run the following commands:${normal}"
echo 'git clone https://github.com/spaceship-prompt/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt" --depth=1'
echo 'ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"'


rm -rf $HOME/.hammerspoon
ln -s $DOTFILES/mac/.hammerspoon $HOME/.hammerspoon
echo 'SimLink created: Hammerspoon'
