module frontend;

import slf4d;

import app.frontend;

class CLIFrontend: Frontend {
    int run(string configurationPath, string[] args) {
        getLogger().error("Not implemented.");
        return 0;
    }
}

Frontend makeFrontend() => new CLIFrontend();
