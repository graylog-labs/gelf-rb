module GELF
  # There are two things you should know about log levels/severity:
  #  - syslog defines levels from 0 (Emergency) to 7 (Debug).
  #    0 (Emergency) and 1 (Alert) levels are reserved for OS kernel.
  #  - Ruby default Logger defines levels from 0 (DEBUG) to 4 (FATAL) and 5 (UNKNOWN).
  #    Note that order is inverted.
  # For compatibility we define our constants as Ruby Logger, and convert values before
  # generating GELF message, using defined mapping.

  module Levels
    DEBUG   = 0
    INFO    = 1
    WARN    = 2
    ERROR   = 3
    FATAL   = 4
    UNKNOWN = 5
  end

  include Levels

  # Maps Ruby Logger levels to syslog levels as SyslogLogger and syslogger gems. This one is default.
  LOGGER_MAPPING = {DEBUG   => 7, # Debug
                    INFO    => 6, # Info
                    WARN    => 5, # Notice
                    ERROR   => 4, # Warning
                    FATAL   => 3, # Error
                    UNKNOWN => 1} # Alert – shouldn't be used

  # Maps Ruby Logger levels to syslog levels as is.
  DIRECT_MAPPING = {DEBUG   => 7, # Debug
                    INFO    => 6, # Info
                    # skip 5 Notice
                    WARN    => 4, # Warning
                    ERROR   => 3, # Error
                    FATAL   => 2, # Critical
                    UNKNOWN => 1} # Alert – shouldn't be used
end
