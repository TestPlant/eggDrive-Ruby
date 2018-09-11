require_relative './point'
require_relative './dimension'

class EggDrive
  class DriveResult

    attr_reader :output, :duration, :return_value, :result, :fault_code, :fault_string

    def self.new_success(output, duration, return_value, result)
      self.new(output, duration, return_value, result)
    end

    def self.new_error(fault_code, fault_string)
      self.new(nil, nil, nil, nil, fault_code, fault_string)
    end

    def initialize(output, duration, return_value, result, fault_code=nil, fault_string=nil)
      @output = output
      @duration = duration
      @return_value = return_value
      @result = result
      @fault_code = fault_code
      @fault_string = fault_string
      @success = !(@fault_code || @fault_string)
    end


    def print_if_error
      STDERR.puts "#{@fault_code} #{@fault_string}"
    end

    def succeeded?
      @success
    end

    def as_point
      Point.new(@return_value[0].to_i,@return_value[1].to_i)
    end

    def as_points
      @return_value.map do |item|
          Point.new(item[0].to_i, item[1].to_i)
      end
    end

    def as_dimension
      Dimension.new(@return_value[0].to_i, @return_value[1].to_i)
    end

    def as_hash
      @return_value
    end

    def as_array
      @return_value
    end

  end
end