if ! is-executable ruby; then
    echo "Skipped: missing ruby"
    return
fi

echo "==> ${BOLD}Installing gems${NORMAL}"

gems=(
)

for gem in ${gems[@]}; do
    gem list -i $gem &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Installing $gem"
        gem install $gem
    else
        version=$(gem list | grep $gem | awk '{print $2}' | sed 's/[()]//g')
        echo "$gem ($version) is already installed"
    fi
done

echo ""
