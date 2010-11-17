module GELF
  # There are two things you should know about log leves/severity:
  #  - syslog defines levels from 0 (Emergency) to 7 (Debug).
  #    0 (Emergency) and 1 (Alert) levels are reserved for OS kernel.
  #  - Ruby default Logger defines levels from 0 (DEBUG) to 4 (FATAL) and 5 (UNKNOWN).
  #    Note that order is inverted. Also syslog level 5 (Notice) is skipped.
  # For compatibility we define our constants as Ruby Logger, and convert values before
  # generating GELF message.

  module Levels
    DEBUG   = 0
    INFO    = 1
    WARN    = 2
    ERROR   = 3
    FATAL   = 4
    UNKNOWN = 5
  end

  include Levels

  # Maps Ruby Logger levels (and methods) to syslog levels.
  LEVELS_MAPPING = {  :debug   => 7,
                      :info    => 6,
                      :warn    => 4,
                      :error   => 3,
                      :fatal   => 2,
                      :unknown => 2  }
end
