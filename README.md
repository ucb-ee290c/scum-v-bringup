# scum-v-bringup

Various files for bringing up the Single-Chip Micro Mote V (SCμM-V)

## Documentation

📖 **[SCuM-V Documentation (Nextra Site)](https://ucb-ee290c.github.io/scum-v-bringup/)** - Interactive documentation

### Contributing to Documentation
- **Nextra Documentation**: Edit files in `docs/` and submit pull requests
- **Legacy AsciiDoc**: See [Contributing to the specification document](docs/README.md)

### Installing Node.js and npm

npm is bundled with Node.js. Install Node.js for your OS, then verify with `node -v` and `npm -v`.

- **Windows**:
  - Download the LTS installer from the [official Node.js download page](https://nodejs.org/en/download/)
  - Run the `.msi` and follow the prompts
  - Verify: `node -v` and `npm -v`

- **macOS**:
  - Install Homebrew (if not installed):
    ```bash
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```
  - Install Node.js (includes npm):
    ```bash
    brew install node
    ```
  - Verify: `node -v` and `npm -v`

- **Linux (Ubuntu/Debian)**:
  - Update and install:
    ```bash
    sudo apt update
    sudo apt install nodejs npm
    ```
  - Verify: `node -v` and `npm -v`

- **More options**: See the official npm guide: [Downloading and installing Node.js and npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)

#### How to contribute to the docs
1. Fork the repo on GitHub: [ucb-ee290c/scum-v-bringup](https://github.com/ucb-ee290c/scum-v-bringup)
2. Clone your fork:
   ```bash
   git clone https://github.com/<your-username>/scum-v-bringup.git
   cd scum-v-bringup
   ```
3. Create a branch:
   ```bash
   git checkout -b docs/your-change
   ```
4. Edit files under `docs/`, preview locally (below), commit and push:
   ```bash
   git add .
   git commit -m "docs: describe your change"
   git push origin docs/your-change
   ```
5. Open a Pull Request to `ucb-ee290c/scum-v-bringup` with a clear description.

### Building Documentation Locally
```bash
cd docs
npm install
npm run dev    # Development server at http://localhost:3000
npm run build  # Production build
```


