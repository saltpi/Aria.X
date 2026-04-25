#ifndef Aria2Core_hpp
#define Aria2Core_hpp

#include <string>
#include <vector>
#include <thread>
#include <aria2/aria2.h>

// 使用命名空间以便 Swift 更好地识别
namespace aria2_manager {

class Aria2Core {
public:
    Aria2Core();
    ~Aria2Core();

    bool start(int port, const std::string& secret, const std::string& downloadDir);
    void stop();
    void saveSession();
    bool isRunning() const;

private:
    aria2::Session* session;
    bool running;
};

} // namespace aria2_manager

#endif
