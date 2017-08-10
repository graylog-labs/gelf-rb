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
    # Additional native syslog severities. These will work in direct mapping mode
    # only, for compatibility with syslog sources unrelated to Logger.
    EMERGENCY     = 10
    ALERT         = 11
    CRITICAL      = 12
    WARNING       = 14
    NOTICE        = 15
    INFORMATIONAL = 16
  end

  include Levels

  # Maps Ruby Logger levels to syslog levels as SyslogLogger and syslogger gems. This one is default.
  LOGGER_MAPPING = {DEBUG   => 7, # Debug
                    INFO    => 6, # Informational
                    WARN    => 5, # Notice
                    ERROR   => 4, # Warning
                    FATAL   => 3, # Error
                    UNKNOWN => 1} # Alert – shouldn't be used

  # Maps Syslog or Ruby Logger levels directly to standard syslog numerical severities.
  DIRECT_MAPPING = {DEBUG         => 7, # Debug
                    INFORMATIONAL => 6, # Informational (syslog source)
                    INFO          => 6, # Informational (Logger source)
                    NOTICE        => 5, # Notice
                    WARNING       => 4, # Warning (syslog source)
                    WARN          => 4, # Warning (Logger source)
                    ERROR         => 3, # Error
                    CRITICAL      => 2, # Critical (syslog source)
                    FATAL         => 2, # Critical (Logger source)
                    ALERT         => 1, # Alert (syslog source)
                    UNKNOWN       => 1, # Alert - shouldn't be used (Logger source)
                    EMERGENCY     => 0} # Emergency (syslog source)
end
