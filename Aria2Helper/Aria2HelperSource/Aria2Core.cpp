#include "Aria2Core.hpp"
#include <iostream>

namespace aria2_manager {

Aria2Core::Aria2Core() : session(nullptr), running(false) {
    aria2::libraryInit();
}

Aria2Core::~Aria2Core() {
    stop();
    aria2::libraryDeinit();
}

bool Aria2Core::start(int port, const std::string& secret, const std::string& downloadDir) {
    if (running) return true;

    aria2::SessionConfig config;
    config.keepRunning = true;
    // 移除导致错误的成员设置
    // config.useDefaultHandlers = true; 

    std::vector<std::pair<std::string, std::string>> options;
    options.push_back({"enable-rpc", "true"});
    options.push_back({"rpc-listen-port", std::to_string(port)});
    options.push_back({"rpc-secret", secret});
    options.push_back({"dir", downloadDir});
    options.push_back({"rpc-allow-origin-all", "true"});
    
    std::string sessionFile = downloadDir + "/aria2.session";
    options.push_back({"input-file", sessionFile});
    options.push_back({"save-session", sessionFile});
    options.push_back({"save-session-interval", "60"});

    session = aria2::sessionNew(options, config);
    if (!session) {
        return false;
    }

    running = true;
    
    // 在后台线程运行 loop
    std::thread([this]() {
        while (running) {
            int result = aria2::run(session, aria2::RUN_ONCE);
            if (result != 1) { // 1 means continue
                break;
            }
        }
        running = false;
    }).detach();

    return true;
}

void Aria2Core::saveSession() {
    if (session) {
        // aria2 does not have a direct "save" call for the whole session in the lib
        // but it saves when the session is closed/finalized.
        // Or we can rely on the fact that we set save-session-interval.
    }
}

void Aria2Core::stop() {
    if (!running) return;
    running = false;
    if (session) {
        // sessionFinal will save the session if save-session is set
        aria2::sessionFinal(session);
        session = nullptr;
    }
}

bool Aria2Core::isRunning() const {
    return running;
}

} // namespace aria2_manager
