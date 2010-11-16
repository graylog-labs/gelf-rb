module GELF
  # Emergency (0) and Alert (1) are reserved for OS kernel.
  LEVELS = {  :critical  => 2,
              :error     => 3,
              :warning   => 4,
              :notice    => 5,
              :info      => 6,
              :debug     => 7  }

  LEVELS.each do |k, v|
    const_set(k.to_s.upcase, v)
  end

  LEVELS_EXT = { :warn => :warning, :fatal => :critical }

  LEVELS_EXT.each do |k, v|
    const_set(k.to_s.upcase, LEVELS[v])
  end
end
