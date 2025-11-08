#!/usr/bin/env bash

VERSION="1.0.0"

if [ -d "/data/data/com.termux" ]; then
    PREFIX="/data/data/com.termux/files/usr"
    BIN_DIR="$PREFIX/bin"
    IS_TERMUX=1
else
    BIN_DIR="$HOME/.local/bin"
    IS_TERMUX=0
fi

LOG_DIR="$HOME/.local/share/tup"
LOG_FILE="$LOG_DIR/logs.txt"

COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[1;34m"
COLOR_CYAN="\033[1;36m"
COLOR_MAGENTA="\033[1;35m"

show_banner() {
    clear
    echo -e "${COLOR_CYAN}"
    echo "┌──────────────────────────────────────────────────┐"
    echo "│                                                  │"
    echo "│              ░▀█▀░█░█░█▀█                        │"
    echo "│              ░░█░░█░█░█▀▀                        │"
    echo "│              ░░▀░░▀▀▀░▀░░                        │"
    echo "│                                                  │"
    echo "│           🚀 TUP - Tool Installer 🚀             │"
    echo "│              Version: $VERSION                      │"
    echo "│              Made by: Taz                        │"
    echo "│                                                  │"
    echo "└──────────────────────────────────────────────────┘"
    echo -e "${COLOR_RESET}\n"
}

initial_setup() {
    echo -e "${COLOR_YELLOW}[*] Starting initial setup...${COLOR_RESET}\n"

    echo -e "${COLOR_CYAN}[*] Checking dependencies...${COLOR_RESET}"

    local deps=("coreutils" "findutils")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null && ! pkg list-installed 2>/dev/null | grep -q "^$dep"; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${COLOR_YELLOW}[*] Installing missing packages: ${missing_deps[*]}${COLOR_RESET}"
        pkg update -y &> /dev/null
        pkg install -y "${missing_deps[@]}" &> /dev/null
        echo -e "${COLOR_GREEN}[✓] Dependencies installed!${COLOR_RESET}\n"
    else
        echo -e "${COLOR_GREEN}[✓] All dependencies are already installed!${COLOR_RESET}\n"
    fi

    if [ ! -d "$BIN_DIR" ]; then
        echo -e "${COLOR_CYAN}[*] Creating bin directory: $BIN_DIR${COLOR_RESET}"
        mkdir -p "$BIN_DIR"
        echo -e "${COLOR_GREEN}[✓] Directory created!${COLOR_RESET}\n"
    else
        echo -e "${COLOR_GREEN}[✓] Bin directory already exists!${COLOR_RESET}\n"
    fi

    if [ ! -d "$LOG_DIR" ]; then
        echo -e "${COLOR_CYAN}[*] Creating log directory: $LOG_DIR${COLOR_RESET}"
        mkdir -p "$LOG_DIR"
        touch "$LOG_FILE"
        echo -e "${COLOR_GREEN}[✓] Log directory created!${COLOR_RESET}\n"
    else
        [ ! -f "$LOG_FILE" ] && touch "$LOG_FILE"
        echo -e "${COLOR_GREEN}[✓] Log directory already exists!${COLOR_RESET}\n"
    fi

    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo -e "${COLOR_CYAN}[*] Adding $BIN_DIR to PATH...${COLOR_RESET}"

        for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
            if [ -f "$rc_file" ]; then
                if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$rc_file"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc_file"
                    echo -e "${COLOR_GREEN}[✓] Added to $(basename $rc_file)${COLOR_RESET}"
                fi
            fi
        done

        export PATH="$BIN_DIR:$PATH"
        echo -e "${COLOR_GREEN}[✓] PATH updated!${COLOR_RESET}\n"
    else
        echo -e "${COLOR_GREEN}[✓] PATH already configured!${COLOR_RESET}\n"
    fi

    echo -e "${COLOR_GREEN}┌──────────────────────────────────┐${COLOR_RESET}"
    echo -e "${COLOR_GREEN}│    ✨ Setup Complete! ✨         │${COLOR_RESET}"
    echo -e "${COLOR_GREEN}└──────────────────────────────────┘${COLOR_RESET}\n"
    echo -e "${COLOR_CYAN}[*] Restart your terminal or run: ${COLOR_YELLOW}source ~/.bashrc${COLOR_RESET}"
    echo -e "${COLOR_CYAN}[*] Usage:${COLOR_RESET}"
    echo -e "    ${COLOR_YELLOW}.add <script>${COLOR_RESET}  - Install a tool"
    echo -e "    ${COLOR_YELLOW}.rm <tool>${COLOR_RESET}     - Remove a tool"
    echo -e "    ${COLOR_YELLOW}.tup${COLOR_RESET}           - Show help"
    echo -e "    ${COLOR_YELLOW}.tupdel${COLOR_RESET}        - Uninstall Tup\n"
}

print_success() { echo -e "${COLOR_GREEN}[✓] $1${COLOR_RESET}"; }
print_error() { echo -e "${COLOR_RED}[✗] $1${COLOR_RESET}"; }
print_info() { echo -e "${COLOR_BLUE}[*] $1${COLOR_RESET}"; }
print_warning() { echo -e "${COLOR_YELLOW}[!] $1${COLOR_RESET}"; }

find_scripts_in_dir() {
    local dir="$1"
    find "$dir" -maxdepth 1 -type f \( -name "*.sh" -o -name "*.py" -o -name "*.pl" -o -name "*.rb" -o -name "*.js" \) 2>/dev/null
}

get_interpreter_path() {
    local interpreter="$1"
    local interp_path
    
    if [ $IS_TERMUX -eq 1 ]; then
        interp_path="$PREFIX/bin/$interpreter"
        if [ -f "$interp_path" ]; then
            echo "$interp_path"
            return 0
        fi
    fi
    
    interp_path=$(command -v "$interpreter" 2>/dev/null)
    if [ -n "$interp_path" ]; then
        echo "$interp_path"
        return 0
    fi
    
    return 1
}

install_tool() {
    local script_path="$1"
    local provided_name="$2"
    local script_name=$(basename "$script_path")
    local name_without_ext="${script_name%.*}"

    if [ ! -f "$script_path" ]; then
        print_error "File not found: $script_path"
        return 1
    fi

    print_info "Installing: $script_name"

    if [ -n "$provided_name" ]; then
        custom_name="$provided_name"
    else
        echo -e "\n${COLOR_CYAN}┌──────────────────────────────────┐${COLOR_RESET}"
        echo -e "${COLOR_CYAN}│       Tool Configuration         │${COLOR_RESET}"
        echo -e "${COLOR_CYAN}└──────────────────────────────────┘${COLOR_RESET}"
        read -p "$(echo -e "${COLOR_YELLOW}Command name [default: $name_without_ext]: ${COLOR_RESET}")" custom_name
    fi

    [ -z "$custom_name" ] && custom_name="$name_without_ext"
    custom_name=$(echo "$custom_name" | tr -d ' ' | tr '[:upper:]' '[:lower:]')
    
    local run_as_root=0
    if [ -n "$SUDO_MODE" ]; then
        run_as_root=1
    else
        read -p "$(echo -e "${COLOR_YELLOW}Run with sudo? [y/N]: ${COLOR_RESET}")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            run_as_root=1
            print_info "Tool will run with sudo"
        fi
    fi
    echo ""

    local shebang=$(head -n1 "$script_path" | tr -d '\n')
    local interpreter=""
    local source_dir=$(dirname "$(realpath "$script_path")")

    if [[ $shebang == \#!/usr/bin/env\ * ]]; then
        interpreter=$(echo "$shebang" | awk '{print $2}')
        print_info "Detected shebang: $shebang"
        
        local interpreter_path=$(get_interpreter_path "$interpreter")
        if [ -n "$interpreter_path" ]; then
            print_info "Using interpreter at: $interpreter_path"
            local temp_file=$(mktemp)
            echo "#!$interpreter_path" > "$temp_file"
            tail -n +2 "$script_path" >> "$temp_file"
            script_path="$temp_file"
        else
            print_error "Interpreter '$interpreter' not found"
            return 1
        fi
    elif [[ $shebang == \#!* ]]; then
        interpreter=$(echo "$shebang" | sed 's|^#!||' | awk '{print $1}')
        print_info "Detected shebang: $shebang"
    else
        case "${script_name##*.}" in
            py) interpreter="python" ;;
            sh) interpreter="bash" ;;
            pl) interpreter="perl" ;;
            rb) interpreter="ruby" ;;
            js) interpreter="node" ;;
            *) interpreter="bash" ;;
        esac

        if [ -z "$SHEBANG_INTERPRETER" ]; then
            print_warning "No shebang found. Adding shebang for $interpreter"
        fi
        
        local interpreter_path=$(get_interpreter_path "$interpreter")
        if [ -n "$interpreter_path" ]; then
            local temp_file=$(mktemp)
            echo "#!$interpreter_path" > "$temp_file"
            cat "$script_path" >> "$temp_file"
            script_path="$temp_file"
        else
            print_error "Interpreter '$interpreter' not found"
            return 1
        fi
    fi

    local target_path="$BIN_DIR/$custom_name"

    if [ -f "$target_path" ]; then
        print_warning "Tool '$custom_name' already exists!"
        read -p "$(echo -e "${COLOR_YELLOW}Overwrite? [y/N]: ${COLOR_RESET}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled."
            return 0
        fi
    fi

    if [ $run_as_root -eq 1 ]; then
        local actual_interpreter=$(head -n1 "$script_path" | sed 's|^#!||' | awk '{print $1}')
        local script_content=$(tail -n +2 "$script_path")
        
        cat > "$target_path" << 'WRAPPER_EOF'
#!/usr/bin/env bash
WRAPPER_EOF
        echo "SCRIPT_DIR=\"$source_dir\"" >> "$target_path"
        echo "INTERPRETER=\"$actual_interpreter\"" >> "$target_path"
        cat >> "$target_path" << 'WRAPPER_EOF'
SCRIPT_CONTENT=$(cat << 'INLINE_SCRIPT_END'
WRAPPER_EOF
        echo "$script_content" >> "$target_path"
        cat >> "$target_path" << 'WRAPPER_EOF'
INLINE_SCRIPT_END
)
cd "$SCRIPT_DIR"
echo "$SCRIPT_CONTENT" | sudo "$INTERPRETER" - "$@"
WRAPPER_EOF
        chmod +x "$target_path"
        chmod 755 "$target_path"
        echo "$custom_name:$script_path:$(date):sudo" >> "$LOG_FILE"
    else
        cp "$script_path" "$target_path"
        chmod +x "$target_path"
        chmod 755 "$target_path"
        echo "$custom_name:$script_path:$(date)" >> "$LOG_FILE"
    fi

    local all_files_in_dir=($(find "$source_dir" -maxdepth 1 -type f ! -name "$script_name" 2>/dev/null))
    if [ ${#all_files_in_dir[@]} -gt 0 ]; then
        print_info "Installing dependency files..."
        for dep_file in "${all_files_in_dir[@]}"; do
            dep_name=$(basename "$dep_file")
            dep_target="$BIN_DIR/$dep_name"
            if [ ! -f "$dep_target" ]; then
                cp "$dep_file" "$dep_target" 2>/dev/null
                chmod +x "$dep_target" 2>/dev/null
            fi
        done
    fi

    print_success "Tool installed successfully!"
    echo -e "${COLOR_CYAN}┌──────────────────────────────────┐${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│  Run with: ${COLOR_MAGENTA}$custom_name${COLOR_CYAN}                │${COLOR_RESET}"
    if [ $run_as_root -eq 1 ]; then
        echo -e "${COLOR_CYAN}│  Mode: ${COLOR_YELLOW}Sudo Enabled${COLOR_CYAN}              │${COLOR_RESET}"
    fi
    echo -e "${COLOR_CYAN}└──────────────────────────────────┘${COLOR_RESET}\n"

    [[ "$script_path" == /tmp/tmp.* ]] && rm -f "$script_path"
}

create_add_script() {
    if [ ! -f "$BIN_DIR/.add" ]; then
        cat > "$BIN_DIR/.add" << 'ADD_SCRIPT'
#!/usr/bin/env bash
export TUP_FROM_ADD=1
script_dir="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
tup_script="$script_dir/../../home/.local/share/tup/tup.sh"
if [ -f "$tup_script" ]; then
    exec "$tup_script" "$@"
else
    echo "Error: Tup script not found!"
    exit 1
fi
ADD_SCRIPT
        chmod +x "$BIN_DIR/.add"
        print_success "Add command (.add) installed!"
    fi
}

create_help_script() {
    cat > "$BIN_DIR/.tup" << 'EOF'
#!/usr/bin/env bash

COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[1;34m"
COLOR_CYAN="\033[1;36m"
COLOR_MAGENTA="\033[1;35m"
COLOR_WHITE="\033[1;37m"

show_help() {
    clear
    echo -e "${COLOR_CYAN}"
    echo "┌──────────────────────────────────────────────────┐"
    echo "│                                                  │"
    echo "│              ░▀█▀░█░█░█▀█                        │"
    echo "│              ░░█░░█░█░█▀▀                        │"
    echo "│              ░░▀░░▀▀▀░▀░░                        │"
    echo "│                                                  │"
    echo "│           🚀 TUP - Tool Installer 🚀             │"
    echo "│              Version: 1.0.0                      │"
    echo "│              Made by: Taz                        │"
    echo "│                                                  │"
    echo "└──────────────────────────────────────────────────┘"
    echo -e "${COLOR_RESET}\n"

    echo -e "${COLOR_GREEN}┌──────────────────────────────────────────────────┐${COLOR_RESET}"
    echo -e "${COLOR_GREEN}│                 📖 COMMANDS                      │${COLOR_RESET}"
    echo -e "${COLOR_GREEN}└──────────────────────────────────────────────────┘${COLOR_RESET}\n"
    
    echo -e "  ${COLOR_YELLOW}.add <script>${COLOR_RESET}    Install tool from script file"
    echo -e "  ${COLOR_YELLOW}.add${COLOR_RESET}            Auto-detect scripts in current dir"
    echo -e "  ${COLOR_YELLOW}.add cd <dir>${COLOR_RESET}   Install from specific directory"
    echo -e "  ${COLOR_YELLOW}.rm <tool>${COLOR_RESET}      Remove an installed tool"
    echo -e "  ${COLOR_YELLOW}.rm all${COLOR_RESET}         Remove ALL Tup tools"
    echo -e "  ${COLOR_YELLOW}.tup${COLOR_RESET}            Show this help menu"
    echo -e "  ${COLOR_YELLOW}.tupdel${COLOR_RESET}         Uninstall Tup completely\n"

    echo -e "${COLOR_BLUE}┌──────────────────────────────────────────────────┐${COLOR_RESET}"
    echo -e "${COLOR_BLUE}│              📋 SUPPORTED FORMATS                │${COLOR_RESET}"
    echo -e "${COLOR_BLUE}└──────────────────────────────────────────────────┘${COLOR_RESET}\n"
    
    echo -e "  ${COLOR_MAGENTA}•${COLOR_RESET} .sh  - Bash scripts"
    echo -e "  ${COLOR_MAGENTA}•${COLOR_RESET} .py  - Python scripts"
    echo -e "  ${COLOR_MAGENTA}•${COLOR_RESET} .pl  - Perl scripts"
    echo -e "  ${COLOR_MAGENTA}•${COLOR_RESET} .rb  - Ruby scripts"
    echo -e "  ${COLOR_MAGENTA}•${COLOR_RESET} .js  - Node.js scripts\n"

    echo -e "${COLOR_CYAN}┌──────────────────────────────────────────────────┐${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│                💡 EXAMPLES                       │${COLOR_RESET}"
    echo -e "${COLOR_CYAN}└──────────────────────────────────────────────────┘${COLOR_RESET}\n"
    
    echo -e "  ${COLOR_YELLOW}.add install.sh${COLOR_RESET}          Install 'install.sh'"
    echo -e "  ${COLOR_YELLOW}.add myscript.py${COLOR_RESET}         Install Python script"
    echo -e "  ${COLOR_YELLOW}.add cd ~/scripts${COLOR_RESET}        Install from ~/scripts"
    echo -e "  ${COLOR_YELLOW}.rm mytool${COLOR_RESET}               Remove 'mytool'\n"

    echo -e "${COLOR_GREEN}┌──────────────────────────────────────────────────┐${COLOR_RESET}"
    echo -e "${COLOR_GREEN}│              📁 INSTALL LOCATION                 │${COLOR_RESET}"
    echo -e "${COLOR_GREEN}└──────────────────────────────────────────────────┘${COLOR_RESET}\n"
    
    if [ -d "/data/data/com.termux" ]; then
        echo -e "  ${COLOR_MAGENTA}/data/data/com.termux/files/usr/bin${COLOR_RESET}\n"
    else
        echo -e "  ${COLOR_MAGENTA}$HOME/.local/bin${COLOR_RESET}\n"
    fi
    
    echo -e "${COLOR_YELLOW}💡 TIP:${COLOR_RESET} After install, restart terminal or run:"
    echo -e "   ${COLOR_CYAN}source ~/.bashrc${COLOR_RESET}\n"
}

show_help
EOF
    chmod +x "$BIN_DIR/.tup"
}

create_remove_script() {
    cat > "$BIN_DIR/.rm" << 'EOF'
#!/usr/bin/env bash

COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_YELLOW="\033[1;33m"
COLOR_CYAN="\033[1;36m"

print_success() { echo -e "${COLOR_GREEN}[✓] $1${COLOR_RESET}"; }
print_error() { echo -e "${COLOR_RED}[✗] $1${COLOR_RESET}"; }
print_info() { echo -e "${COLOR_CYAN}[*] $1${COLOR_RESET}"; }

if [ -d "/data/data/com.termux" ]; then
    BIN_DIR="/data/data/com.termux/files/usr/bin"
else
    BIN_DIR="$HOME/.local/bin"
fi

LOG_DIR="$HOME/.local/share/tup"
LOG_FILE="$LOG_DIR/logs.txt"

if [ $# -eq 0 ]; then
    print_error "Usage: .rm <tool_name> | .rm all"
    exit 1
fi

if [ "$1" == "cd" ] || [ "$1" == "add" ]; then
    if [ -z "$2" ]; then
        print_error "Usage: .rm <tool_name>"
        exit 1
    fi
    tool_name="$2"
else
    tool_name="$1"
fi

if [ "$tool_name" == "add" ] || [ "$tool_name" == "rm" ] || [ "$tool_name" == "tup" ] || [ "$tool_name" == "tupdel" ]; then
    print_error "Cannot remove internal Tup command: .$tool_name"
    exit 1
fi

if [ "$tool_name" == "all" ]; then
    read -p "$(echo -e "${COLOR_YELLOW}Remove ALL Tup-installed tools? [y/N]: ${COLOR_RESET}")" -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ ! -f "$LOG_FILE" ] || [ ! -s "$LOG_FILE" ]; then
            print_error "No tools installed by Tup found!"
            exit 1
        fi

        count=0
        while IFS=':' read -r tool_name_log tool_path_log _; do
            if [ -f "$BIN_DIR/$tool_name_log" ]; then
                rm -f "$BIN_DIR/$tool_name_log"
                ((count++))
            fi
        done < "$LOG_FILE"

        source_dirs=()
        while IFS=':' read -r _ tool_path_log _; do
            if [ -n "$tool_path_log" ] && [ -f "$tool_path_log" ]; then
                source_dir=$(dirname "$tool_path_log")
                if [[ ! " ${source_dirs[@]} " =~ " ${source_dir} " ]]; then
                    source_dirs+=("$source_dir")
                fi
            fi
        done < "$LOG_FILE"

        for source_dir in "${source_dirs[@]}"; do
            if [ -d "$source_dir" ]; then
                for dep_file in "$source_dir"/*; do
                    if [ -f "$dep_file" ]; then
                        dep_name=$(basename "$dep_file")
                        dep_target="$BIN_DIR/$dep_name"
                        if [ -f "$dep_target" ]; then
                            is_logged=0
                            while IFS=':' read -r log_name _ _; do
                                if [ "$log_name" == "$dep_name" ]; then
                                    is_logged=1
                                    break
                                fi
                            done < "$LOG_FILE"
                            
                            if [ $is_logged -eq 1 ]; then
                                rm -f "$dep_target" 2>/dev/null
                            fi
                        fi
                    fi
                done
            fi
        done

        > "$LOG_FILE"
        print_success "All $count Tup tools removed successfully!"
    else
        print_info "Removal cancelled."
    fi
    exit 0
fi

tool_path="$BIN_DIR/$tool_name"

if [ ! -f "$tool_path" ]; then
    print_error "Tool '$tool_name' not found!"
    exit 1
fi

read -p "$(echo -e "${COLOR_YELLOW}Remove \"$tool_name\"? [y/N]: ${COLOR_RESET}")" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "$tool_path"
    
    if [ -f "$LOG_FILE" ]; then
        source_dir=""
        while IFS=':' read -r log_name log_path _; do
            if [ "$log_name" == "$tool_name" ] && [ -n "$log_path" ]; then
                source_dir=$(dirname "$log_path")
                break
            fi
        done < "$LOG_FILE"
        
        if [ -n "$source_dir" ] && [ -d "$source_dir" ]; then
            for dep_file in "$source_dir"/*; do
                if [ -f "$dep_file" ]; then
                    dep_name=$(basename "$dep_file")
                    dep_target="$BIN_DIR/$dep_name"
                    if [ -f "$dep_target" ] && [ "$dep_name" != "$tool_name" ]; then
                        tool_count=$(grep -c ":$source_dir/" "$LOG_FILE" 2>/dev/null || echo "0")
                        if [ "$tool_count" -le 1 ]; then
                            rm -f "$dep_target" 2>/dev/null
                        fi
                    fi
                fi
            done
        fi
        
        sed -i "/^$tool_name:/d" "$LOG_FILE" 2>/dev/null
    fi
    
    print_success "Tool '$tool_name' and dependencies removed successfully!"
else
    print_info "Removal cancelled."
fi
EOF
    chmod +x "$BIN_DIR/.rm"
}

create_uninstall_script() {
    cat > "$BIN_DIR/.tupdel" << 'EOF'
#!/usr/bin/env bash

COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_YELLOW="\033[1;33m"
COLOR_CYAN="\033[1;36m"

print_success() { echo -e "${COLOR_GREEN}[✓] $1${COLOR_RESET}"; }
print_error() { echo -e "${COLOR_RED}[✗] $1${COLOR_RESET}"; }
print_info() { echo -e "${COLOR_CYAN}[*] $1${COLOR_RESET}"; }

if [ -d "/data/data/com.termux" ]; then
    BIN_DIR="/data/data/com.termux/files/usr/bin"
else
    BIN_DIR="$HOME/.local/bin"
fi

echo -e "${COLOR_RED}"
echo "┌────────────────────────────────────────────────┐"
echo "│                                                │"
echo "│               ░▀█▀░█░█░█▀█                     │"
echo "│               ░░█░░█░█░█▀▀                     │"
echo "│               ░░▀░░▀▀▀░▀░░                     │"
echo "│                                                │"
echo "│               ⚠️  UNINSTALL TUP ⚠️               │"
echo "│          This removes ALL Tup tools            │"
echo "│             and configuration                  │"
echo "│                                                │"
echo "└────────────────────────────────────────────────┘"
echo -e "${COLOR_RESET}\n"

read -p "$(echo -e "${COLOR_YELLOW}Are you sure you want to uninstall Tup? [y/N]: ${COLOR_RESET}")" -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Removing Tup..."
    
    print_info "Removing all Tup-installed tools..."
    if [ -f "$HOME/.local/share/tup/logs.txt" ] && [ -s "$HOME/.local/share/tup/logs.txt" ]; then
        tool_count=0
        while IFS=':' read -r tool_name_log tool_path_log _; do
            if [ -f "$BIN_DIR/$tool_name_log" ]; then
                rm -f "$BIN_DIR/$tool_name_log"
                ((tool_count++))
            fi
        done < "$HOME/.local/share/tup/logs.txt"
        
        source_dirs=()
        while IFS=':' read -r _ tool_path_log _; do
            if [ -n "$tool_path_log" ] && [ -f "$tool_path_log" ]; then
                source_dir=$(dirname "$tool_path_log")
                if [[ ! " ${source_dirs[@]} " =~ " ${source_dir} " ]]; then
                    source_dirs+=("$source_dir")
                fi
            fi
        done < "$HOME/.local/share/tup/logs.txt"
        
        for source_dir in "${source_dirs[@]}"; do
            if [ -d "$source_dir" ]; then
                for dep_file in "$source_dir"/*; do
                    if [ -f "$dep_file" ]; then
                        dep_name=$(basename "$dep_file")
                        dep_target="$BIN_DIR/$dep_name"
                        if [ -f "$dep_target" ]; then
                            is_logged=0
                            while IFS=':' read -r log_name _ _; do
                                if [ "$log_name" == "$dep_name" ]; then
                                    is_logged=1
                                    break
                                fi
                            done < "$HOME/.local/share/tup/logs.txt"
                            
                            if [ $is_logged -eq 1 ]; then
                                rm -f "$dep_target" 2>/dev/null
                            fi
                        fi
                    fi
                done
            fi
        done
        
        print_info "Removed $tool_count tools and their dependencies"
    fi
    
    print_info "Removing Tup commands..."
    rm -f "$BIN_DIR/.add"
    rm -f "$BIN_DIR/.rm"
    rm -f "$BIN_DIR/.tup"
    rm -f "$BIN_DIR/.tupdel"

    print_info "Removing Tup configuration and logs..."
    rm -rf "$HOME/.local/share/tup"

    print_info "Removing any temp files..."
    rm -f /tmp/tmp.* 2>/dev/null

    print_success "Tup uninstalled completely!"
    echo -e "\n${COLOR_CYAN}┌──────────────────────────────────┐${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│   Thank you for using Tup!       │${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│        Made by: Taz              │${COLOR_RESET}"
    echo -e "${COLOR_CYAN}└──────────────────────────────────┘${COLOR_RESET}\n"
else
    print_info "Uninstallation cancelled."
fi
EOF
    chmod +x "$BIN_DIR/.tupdel"
}

self_install() {
    mkdir -p "$LOG_DIR"
    cp "$(realpath "$0")" "$LOG_DIR/tup.sh"
    chmod +x "$LOG_DIR/tup.sh"
    create_add_script
    create_remove_script
    create_uninstall_script
    create_help_script
}

select_file_by_name() {
    local files=("$@")
    clear
    echo -e "${COLOR_CYAN}Available files:${COLOR_RESET}\n"
    for i in "${!files[@]}"; do
        echo -e "  ${COLOR_YELLOW}[$((i+1))]${COLOR_RESET} $(basename "${files[$i]}")"
    done
    echo ""
    echo -e "${COLOR_YELLOW}You can also type the file name directly${COLOR_RESET}\n"
    read -p "$(echo -e "${COLOR_CYAN}Enter name or number: ${COLOR_RESET}")" selection

    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#files[@]}" ]; then
        return $((selection-1))
    fi

    for i in "${!files[@]}"; do
        if [[ "$(basename "${files[$i]}")" == "$selection" ]]; then
            return $i
        fi
    done

    return -1
}

if [ ! -d "$LOG_DIR" ] || [ ! -f "$LOG_FILE" ] || [ ! -f "$BIN_DIR/.add" ]; then
    show_banner
    initial_setup
    self_install
    exit 0
fi

if [ -z "$TUP_FROM_ADD" ]; then
    show_banner
    print_success "Tup is already installed!"
    echo -e "${COLOR_CYAN}┌──────────────────────────────────┐${COLOR_RESET}"
    echo -e "${COLOR_CYAN}│       Available Commands         │${COLOR_RESET}"
    echo -e "${COLOR_CYAN}└──────────────────────────────────┘${COLOR_RESET}\n"
    echo -e "  ${COLOR_YELLOW}.add${COLOR_RESET}     - Install a tool"
    echo -e "  ${COLOR_YELLOW}.rm${COLOR_RESET}      - Remove a tool"
    echo -e "  ${COLOR_YELLOW}.tup${COLOR_RESET}     - Show help"
    echo -e "  ${COLOR_YELLOW}.tupdel${COLOR_RESET}  - Uninstall Tup\n"
    exit 0
fi

show_banner

if [ $# -eq 0 ]; then
    print_info "Searching for scripts in current directory..."

    scripts=($(find_scripts_in_dir "."))

    if [ ${#scripts[@]} -eq 0 ]; then
        print_error "No scripts found in current directory!"
        echo -e "${COLOR_CYAN}Supported formats: .sh, .py, .pl, .rb, .js${COLOR_RESET}"
        exit 1
    fi

    if [ ${#scripts[@]} -eq 1 ]; then
        script_name=$(basename "${scripts[0]}")
        read -p "$(echo -e "${COLOR_YELLOW}Install \"$script_name\"? [Y/n]: ${COLOR_RESET}")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_info "Installation cancelled."
            exit 0
        fi
        install_tool "${scripts[0]}"
    else
        echo -e "${COLOR_CYAN}Multiple scripts found:${COLOR_RESET}"
        for i in "${!scripts[@]}"; do
            echo -e "  ${COLOR_YELLOW}[$((i+1))]${COLOR_RESET} $(basename ${scripts[$i]})"
        done
        echo ""
        echo -e "${COLOR_YELLOW}[a]${COLOR_RESET} Install all scripts"
        echo -e "${COLOR_YELLOW}[q]${COLOR_RESET} Quit"
        echo ""
        read -p "$(echo -e "${COLOR_YELLOW}Select option: ${COLOR_RESET}")" selection

        if [[ "$selection" =~ ^[Qq]$ ]]; then
            print_info "Installation cancelled."
            exit 0
        elif [[ "$selection" =~ ^[Aa]$ ]]; then
            if select_file_by_name "${scripts[@]}"; then
                selected_index=$?
                main_script="${scripts[$selected_index]}"
                main_name=$(basename "$main_script")
                main_name="${main_name%.*}"

                echo -e "\n${COLOR_CYAN}┌──────────────────────────────────┐${COLOR_RESET}"
                echo -e "${COLOR_CYAN}│    Batch Installation Setup      │${COLOR_RESET}"
                echo -e "${COLOR_CYAN}└──────────────────────────────────┘${COLOR_RESET}"
                read -p "$(echo -e "${COLOR_YELLOW}Main command name [default: $main_name]: ${COLOR_RESET}")" custom_name

                [ -z "$custom_name" ] && custom_name="$main_name"
                custom_name=$(echo "$custom_name" | tr -d ' ' | tr '[:upper:]' '[:lower:]')

                read -p "$(echo -e "${COLOR_YELLOW}Run with sudo? [y/N]: ${COLOR_RESET}")" -n 1 -r
                echo
                run_as_root_batch=0
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    run_as_root_batch=1
                fi
                echo ""

                print_info "Installing main command and dependencies..."
                echo -e "${COLOR_BLUE}[*] Main: $(basename "$main_script")${COLOR_RESET}"
                if [ $run_as_root_batch -eq 1 ]; then
                    SHEBANG_INTERPRETER=1 SUDO_MODE=1 install_tool "$main_script" "$custom_name"
                else
                    SHEBANG_INTERPRETER=1 install_tool "$main_script" "$custom_name"
                fi

                print_info "Installing helper files..."
                for script in "${scripts[@]}"; do
                    if [ "$script" != "$main_script" ]; then
                        helper_name=$(basename "$script")
                        target_path="$BIN_DIR/$helper_name"
                        echo -e "${COLOR_BLUE}[*] Helper: $helper_name${COLOR_RESET}"

                        local helper_shebang=$(head -n1 "$script" | tr -d '\n')
                        if [[ $helper_shebang == \#!/usr/bin/env\ * ]]; then
                            local helper_interpreter=$(echo "$helper_shebang" | awk '{print $2}')
                            local helper_interpreter_path=$(get_interpreter_path "$helper_interpreter")
                            if [ -n "$helper_interpreter_path" ]; then
                                echo "#!$helper_interpreter_path" > "$target_path"
                                tail -n +2 "$script" >> "$target_path"
                            else
                                cp "$script" "$target_path"
                            fi
                        else
                            cp "$script" "$target_path"
                        fi
                        chmod +x "$target_path" 2>/dev/null
                    fi
                done

                print_success "Installation complete!"
                echo -e "${COLOR_CYAN}┌──────────────────────────────────┐${COLOR_RESET}"
                echo -e "${COLOR_CYAN}│  Main command: ${COLOR_MAGENTA}$custom_name${COLOR_CYAN}          │${COLOR_RESET}"
                echo -e "${COLOR_CYAN}└──────────────────────────────────┘${COLOR_RESET}\n"
            else
                print_error "Invalid selection!"
                exit 1
            fi
        elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#scripts[@]}" ]; then
            install_tool "${scripts[$((selection-1))]}"
        else
            print_error "Invalid selection!"
            exit 1
        fi
    fi

elif [ "$1" == "cd" ]; then
    if [ -z "$2" ]; then
        print_error "Please specify a directory!"
        exit 1
    fi

    target_dir="$2"

    if [ ! -d "$target_dir" ]; then
        print_error "Directory not found: $target_dir"
        exit 1
    fi

    print_info "Searching for scripts in: $target_dir"

    scripts=($(find_scripts_in_dir "$target_dir"))

    if [ ${#scripts[@]} -eq 0 ]; then
        print_error "No scripts found in $target_dir!"
        exit 1
    fi

    if [ ${#scripts[@]} -eq 1 ]; then
        script_name=$(basename "${scripts[0]}")
        read -p "$(echo -e "${COLOR_YELLOW}Install \"$script_name\"? [Y/n]: ${COLOR_RESET}")" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_info "Installation cancelled."
            exit 0
        fi
        install_tool "${scripts[0]}"
    else
        echo -e "${COLOR_CYAN}Multiple scripts found:${COLOR_RESET}"
        for i in "${!scripts[@]}"; do
            echo -e "  ${COLOR_YELLOW}[$((i+1))]${COLOR_RESET} $(basename ${scripts[$i]})"
        done
        echo ""
        echo -e "${COLOR_YELLOW}[a]${COLOR_RESET} Install all scripts"
        echo -e "${COLOR_YELLOW}[q]${COLOR_RESET} Quit"
        echo ""
        read -p "$(echo -e "${COLOR_YELLOW}Select option: ${COLOR_RESET}")" selection

        if [[ "$selection" =~ ^[Qq]$ ]]; then
            print_info "Installation cancelled."
            exit 0
        elif [[ "$selection" =~ ^[Aa]$ ]]; then
            if select_file_by_name "${scripts[@]}"; then
                selected_index=$?
                main_script="${scripts[$selected_index]}"
                main_name=$(basename "$main_script")
                main_name="${main_name%.*}"

                echo -e "\n${COLOR_CYAN}┌──────────────────────────────────┐${COLOR_RESET}"
                echo -e "${COLOR_CYAN}│    Batch Installation Setup      │${COLOR_RESET}"
                echo -e "${COLOR_CYAN}└──────────────────────────────────┘${COLOR_RESET}"
                read -p "$(echo -e "${COLOR_YELLOW}Main command name [default: $main_name]: ${COLOR_RESET}")" custom_name

                [ -z "$custom_name" ] && custom_name="$main_name"
                custom_name=$(echo "$custom_name" | tr -d ' ' | tr '[:upper:]' '[:lower:]')

                read -p "$(echo -e "${COLOR_YELLOW}Run with sudo? [y/N]: ${COLOR_RESET}")" -n 1 -r
                echo
                run_as_root_batch=0
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    run_as_root_batch=1
                fi
                echo ""

                print_info "Installing main command and dependencies..."
                echo -e "${COLOR_BLUE}[*] Main: $(basename "$main_script")${COLOR_RESET}"
                if [ $run_as_root_batch -eq 1 ]; then
                    SHEBANG_INTERPRETER=1 SUDO_MODE=1 install_tool "$main_script" "$custom_name"
                else
                    SHEBANG_INTERPRETER=1 install_tool "$main_script" "$custom_name"
                fi

                print_info "Installing helper files..."
                for script in "${scripts[@]}"; do
                    if [ "$script" != "$main_script" ]; then
                        helper_name=$(basename "$script")
                        target_path="$BIN_DIR/$helper_name"
                        echo -e "${COLOR_BLUE}[*] Helper: $helper_name${COLOR_RESET}"

                        local helper_shebang=$(head -n1 "$script" | tr -d '\n')
                        if [[ $helper_shebang == \#!/usr/bin/env\ * ]]; then
                            local helper_interpreter=$(echo "$helper_shebang" | awk '{print $2}')
                            local helper_interpreter_path=$(get_interpreter_path "$helper_interpreter")
                            if [ -n "$helper_interpreter_path" ]; then
                                echo "#!$helper_interpreter_path" > "$target_path"
                                tail -n +2 "$script" >> "$target_path"
                            else
                                cp "$script" "$target_path"
                            fi
                        else
                            cp "$script" "$target_path"
                        fi
                        chmod +x "$target_path" 2>/dev/null
                    fi
                done

                print_success "Installation complete!"
                echo -e "${COLOR_CYAN}┌──────────────────────────────────┐${COLOR_RESET}"
                echo -e "${COLOR_CYAN}│  Main command: ${COLOR_MAGENTA}$custom_name${COLOR_CYAN}          │${COLOR_RESET}"
                echo -e "${COLOR_CYAN}└──────────────────────────────────┘${COLOR_RESET}\n"
            else
                print_error "Invalid selection!"
                exit 1
            fi
        elif [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#scripts[@]}" ]; then
            install_tool "${scripts[$((selection-1))]}"
        else
            print_error "Invalid selection!"
            exit 1
        fi
    fi

else
    script_path="$1"

    if [[ "$script_path" != /* ]]; then
        script_path="./$script_path"
    fi

    install_tool "$script_path"
fi

echo -e "\n${COLOR_GREEN}┌──────────────────────────────────┐${COLOR_RESET}"
echo -e "${COLOR_GREEN}│   Thank you for using Tup!       │${COLOR_RESET}"
echo -e "${COLOR_GREEN}│        Made by: Taz               │${COLOR_RESET}"
echo -e "${COLOR_GREEN}└──────────────────────────────────┘${COLOR_RESET}\n"