# 🚀 Tup - Tool Installer

**TUP (Tool Uploader)** is a simple and powerful script installation tool designed for Termux and Linux environments. Install any script with a custom command name and run it instantly!

## ✨ Features

- 🎯 **Simple Installation** - Install scripts with a single command
- 🔧 **Multiple Languages** - Supports `.sh`, `.py`, `.pl`, `.rb`, `.js` scripts
- 🚀 **Auto-Detection** - Automatically detects script type and interpreter
- 🔐 **Root Support** - Optional sudo/root mode for privileged scripts
- 📦 **Batch Install** - Install multiple scripts at once
- 🧹 **Clean Uninstall** - Complete removal of all installed tools
- 🎨 **Interactive UI** - Beautiful command-line interface

## 📥 Installation

### One-Line Install
```bash
curl -fsSL https://raw.githubusercontent.com/Tazhossain/Tup/main/tup.sh -o tup && chmod u+x tup && mv tup $PREFIX/bin/ && tup
```

### Alternative Method
```bash
curl -sSL https://raw.githubusercontent.com/Tazhossain/Tup/main/tup.sh | bash
```

After installation, restart your terminal or run:
```bash
source ~/.bashrc
```

## 📖 Usage

### Install from Current Directory
```bash
.add
```
Automatically detects all scripts in the current directory.

### Install Specific Script
```bash
.add script.sh
.add myscript.py
.add tool.pl
```

### Install from Directory
```bash
.add cd /path/to/scripts
.add cd ~/my-tools
```

### Remove Installed Tool
```bash
.rm toolname
```

### Remove All Tools
```bash
.rm all
```

### Show Help
```bash
.tup
```

### Uninstall Tup
```bash
.tupdel
```

## 🎯 Examples

### Example 1: Install a Python Script
```bash
.add wifi.py
# Enter command name: wifi
# Run with sudo? y
# Now run: wifi
```

### Example 2: Install Multiple Scripts
```bash
cd my-project
.add
# Select: [a] Install all scripts
# Choose main script from list
# All scripts installed as dependencies
```

### Example 3: Install from Another Directory
```bash
.add cd /sdcard/Download/tools
# Auto-detects all scripts in the directory
```

## 🔧 Supported Script Types

| Extension | Language | Interpreter |
|-----------|----------|-------------|
| `.sh` | Bash | bash |
| `.py` | Python | python |
| `.pl` | Perl | perl |
| `.rb` | Ruby | ruby |
| `.js` | JavaScript | node |

## 🔐 Root/Sudo Mode

When you install a script with sudo mode:
- The tool automatically runs with `sudo` privileges
- No need to type `sudo` before the command
- Example: `wifi` runs as `sudo python wifi.py`

## 📁 Installation Location

**Termux:**
```
/data/data/com.termux/files/usr/bin
```

**Linux:**
```
$HOME/.local/bin
```

## 🎨 Features in Detail

### Auto-Detection
Tup automatically detects:
- Script type (Python, Bash, etc.)
- Shebang lines
- Required interpreters
- Dependencies in the same directory

### Batch Installation
When installing multiple scripts:
1. Select main script to run
2. Other scripts become helper files
3. All installed in the correct directory
4. Dependencies automatically managed

### Clean Removal
- `.rm <tool>` removes the tool and its dependencies
- `.rm all` removes all Tup-installed tools
- `.snaptup` completely uninstalls Tup

## 🛠️ Requirements

- Termux or Linux environment
- Basic utilities: `coreutils`, `findutils`
- Interpreters for your scripts (python, bash, etc.)

## 📋 Commands Reference

| Command | Description |
|---------|-------------|
| `.add` | Install scripts from current directory |
| `.add <script>` | Install specific script |
| `.add cd <dir>` | Install from specific directory |
| `.rm <tool>` | Remove a tool |
| `.rm all` | Remove all tools |
| `.tup` | Show help menu |
| `.tupdel` | Uninstall Tup completely |

## 💡 Tips

- Always use `.add` with the script extension
- Choose meaningful command names (short and memorable)
- Use sudo mode for system-level scripts
- Install related scripts together for better organization

## 🐛 Troubleshooting

**Script not running?**
- Make sure the interpreter is installed
- Check if the script has proper shebang
- Verify PATH with: `echo $PATH`

**Permission denied?**
- Install the script with sudo mode: `.add script.sh` → choose `y` for sudo

**Command not found after install?**
- Restart terminal or run: `source ~/.bashrc`
- Check installation with: `which <command-name>`

## 📜 License

MIT License - Feel free to use and modify!

## 👨‍💻 Author

**Taz**

---

⭐ **Star this repo if you find it useful!**

🐛 **Report bugs or request features via Issues**

📧 **Contact: [https://t.me/tazchatbot]**