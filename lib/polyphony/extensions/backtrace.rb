# frozen_string_literal: true

class ::Fiber
  attr_accessor :__calling_fiber__
  attr_writer :__caller__

  class << self
    alias_method :orig_new, :new
    def new(&block)
      calling_fiber = Fiber.current
      fiber_caller = caller
      orig_new(&block).tap do |f|
        f.__calling_fiber__ = calling_fiber
        f.__caller__ = fiber_caller
      end
    end
  end

  def caller
    @__caller__ ||= []
    if @__calling_fiber__
      @__caller__ + @__calling_fiber__.caller
    else
      @__caller__
    end
  end
end

class ::Exception
  alias_method :orig_initialize, :initialize

  def initialize(*args)
    @__raising_fiber__ = Fiber.current
    orig_initialize(*args)
  end

  alias_method :orig_backtrace, :backtrace
  def backtrace
    unless @backtrace_called
      @backtrace_called = true
      return orig_backtrace
    end
    
    if @__raising_fiber__
      backtrace = orig_backtrace || []
      backtrace + @__raising_fiber__.caller
    else
      orig_backtrace
    end
  end
end
