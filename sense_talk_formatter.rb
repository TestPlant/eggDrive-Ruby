require_relative './point'
require_relative './dimension'
require_relative './rectangle'

class EggDrive
  class SenseTalkFormatter

    def initialize
      reset
    end

    def reset
      @arg_list = []
      @arg_map = {}
      return self
    end

    def as_command(command_name)
      if @arg_map.length > 0 && @arg_list.length > 0
        return "#{command_name} (#{self.class.format_no_parens(@arg_list)}, #{self.class.format_no_parens(@arg_map)})"
      end

      if @arg_map.length > 0
        return "#{command_name} (#{self.class.format_no_parens(@arg_map)})"
      end

      if @arg_list.length > 0
        return "#{command_name} #{self.class.format_no_parens(@arg_list)}"
      end

      return command_name
    end

    def as_function(function_name)
      if @arg_map.length > 0 && @arg_list.length > 0
        return "#{function_name} (#{self.class.format_no_parens(@arg_list)}, #{self.class.format_no_parens(@arg_map)})"
      end

      if @arg_map.length > 0
        return "#{function_name} (#{self.class.format_no_parens(@arg_map)})"
      end

      if @arg_list.length > 0
        return "#{function_name} (#{self.class.format_no_parens(@arg_list)})"
      end

      return "#{function_name}()"
    end

    def add_parameter(object)
      @arg_list.push(object) unless object.nil?
      return self
    end

    def add_quoted_parameter(object)
      @arg_list.push(self.class.quoted(self.class.format_object(object))) unless object.nil?
      return self
    end

    def add_plist_parameter(key, object)
      @arg_map[key] = object unless key.nil? || object.nil?
      return self
    end

    def add_plist_parameters(object)
      object.keys.each do |k,v|
        add_plist_parameter(k,v)
      end unless object.nil?
      return self
    end

    def add_quoted_plist_parameter(key, object)
      @arg_map[key] = self.class.quoted(self.class.format_object(object))
      return self
    end

    def self.quoted(inner)
      return nil if inner.nil?
      return "\"#{inner.gsub("\"", "\" & quote & \"")}\""
    end

    def self.format(object)
      return "(#{self.class.format_no_parens(object)})"
    end

    def self.format_no_parens(object)
      case object.class.to_s
        when "Hash"
          ret = ""
          object.keys.each_with_index do |k,i|
            ret += "#{k}:#{object[k]}"
            ret += ", " unless (i + 1) == object.keys.length
          end
          return ret
        when "Array"
          return object.join(", ")
      end
    end

    def self.format_object(object)
      case object.class.to_s
        when "String"
          return object
        when "TrueClass"
          return object.to_s
        when "FalseClass"
          return object.to_s
        when "Point"
          return "#{object.x}, #{object.y}"
        when "Rectangle"
          return "(#{object.x},#{object.y},)(#{object.x + object.width},#{object.y + object.height})"
        when "Dimension"
          return "#{object.width}, #{object.height}"
        when "Array"
          return self.format(object)
        when "Hash"
          return self.format(object)
        else
          return object.to_s
      end
    end

  end

end