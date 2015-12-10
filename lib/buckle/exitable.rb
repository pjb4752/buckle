module Buckle
  module Exitable
    def normal_exit(message = 'bye', io = $stdout)
      io.puts(message)
      exit 0
    end

    def bad_exit(message, io = $stderr, status: 1)
      io.puts("err: #{message}")
      exit status
    end
  end
end
