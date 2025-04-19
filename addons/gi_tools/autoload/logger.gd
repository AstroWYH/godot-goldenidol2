@tool
extends Node



enum LogLevel{
    INFO, 
    WARN, 
    ERROR, 
}

func write(message: String, level: = LogLevel.INFO) -> void :
    var stamped_message: = "[%s] %s" % [
        Time.get_datetime_string_from_system(), 
        message, 
    ]

    match (level):
        LogLevel.ERROR:
            printerr(stamped_message)
        LogLevel.WARN:
            push_warning(stamped_message)
        _:
            print(stamped_message)


func write_err(message: String) -> void :
    write(message, LogLevel.ERROR)


func write_warn(message: String) -> void :
    write(message, LogLevel.WARN)
