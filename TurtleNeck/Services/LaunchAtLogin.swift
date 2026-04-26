import ServiceManagement

enum LaunchAtLogin {
    static func set(_ enabled: Bool) {
        try? SMAppService.mainApp.register()
        if enabled {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
}
