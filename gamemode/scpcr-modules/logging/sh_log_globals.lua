-- Gamemode default log verbosities and categories. Do NOT edit these. 
-- Feel free to add your own in another file, or below these ones. They MUST be globals to work efficiently.
LogVeryVerbose = SCP.Log.RegisterLogLevel( LogVerbosity(0, "VeryVerbose", Color(0, 170, 255)) )
LogVerbose = SCP.Log.RegisterLogLevel( LogVerbosity(1, "Verbose", Color(0, 213, 255)) )
LogDebug = SCP.Log.RegisterLogLevel( LogVerbosity(2, "Debug", Color(0, 255, 255)) )
LogInfo = SCP.Log.RegisterLogLevel( LogVerbosity(100, "Info", Color(255, 255, 255)) )
LogWarning = SCP.Log.RegisterLogLevel( LogVerbosity(999, "Warning", Color(255, 187, 0)) )
LogError = SCP.Log.RegisterLogLevel( LogVerbosity(999, "Error", Color(255, 90, 90)) )

-- Categories. Same as above, feel free to add your own either under this or as globals elsewhere.
-- Order is category name, and default verbosity
LogConfig = SCP.Log.RegisterLogCategory( LogCategory("Config", LogInfo) )
LogSCP = SCP.Log.RegisterLogCategory( LogCategory("SCP", LogInfo) )
LogRoleManager =  SCP.Log.RegisterLogCategory( LogCategory("RoleManager", LogInfo) )
LogRoundManager = SCP.Log.RegisterLogCategory( LogCategory("RoundManager", LogInfo) )
LogTeamManager = SCP.Log.RegisterLogCategory( LogCategory("TeamManager", LogInfo) )
LogLocalization = SCP.Log.RegisterLogCategory( LogCategory("Localization", LogInfo) )
LogNet = SCP.Log.RegisterLogCategory( LogCategory("Net", LogInfo) )
LogUtils = SCP.Log.RegisterLogCategory( LogCategory("Utils", LogInfo) )
LogUI = SCP.Log.RegisterLogCategory( LogCategory("UI", LogInfo) )

SCP.Log.CurrentVerbosity = LogInfo