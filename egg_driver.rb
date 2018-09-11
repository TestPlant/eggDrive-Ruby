require_relative './sense_talk_formatter'
require_relative './rpc_connector'
require_relative './drive_result'

class EggDrive
  class EggDriver
    attr_accessor :image_search_timeout, :text_search_options, :pinch_duration, :pinch_distance

    include RpcConnector

    def initialize
      @connection_state = ConnectionState.new
      @image_search_timeout = 5
      @text_search_options = nil
      @pinch_duration = nil
      @pinch_distance = nil

      @formatter = SenseTalkFormatter.new
    end

    # region Connection
    # ******************************************************************************

    def connect(server_id=nil, port=nil, type=nil, username=nil, password=nil, ssh_host=nil, ssh_user=nil, ssh_password=nil, visible=nil, color_depth=nil)
      formatter = @formatter.reset
      formatter.add_quoted_plist_parameter("ServerID", server_id)
      formatter.add_plist_parameter("PortNum", port)
      formatter.add_plist_parameter("Type", type)
      formatter.add_quoted_plist_parameter("Username", username)
      formatter.add_quoted_plist_parameter("Password", password)
      formatter.add_quoted_plist_parameter("sshHost", ssh_host)
      formatter.add_quoted_plist_parameter("sshUser", ssh_user)
      formatter.add_quoted_plist_parameter("sshPassword", ssh_password)
      formatter.add_plist_parameter("Visible", visible)
      formatter.add_plist_parameter("ColorDepth", color_depth)

      execute_string(formatter.as_command("Connect"))
      nil
    end

    def disconnect
      execute_string(@formatter.reset.as_command("Disconnect"))
    end

    def connection_info(connection_name=nil)
      execute_string(@formatter.reset.add_quoted_parameter(connection_name).as_function("ConnectionInfo"))
      return @last_drive_result.as_hash
    end

    def remote_screen_size
      execute_string(@formatter.reset.as_function("RemoteScreenSize"))
      return @last_drive_result.as_dimension
    end

    # endregion

    # region Logs
    # ******************************************************************************

    def log(log)
      execute_string(@formatter.reset.add_quoted_parameter(log).as_command("Log"))
    end

    def log_expression(log)
      execute_string(@formatter.reset.add_parameter(log).as_command("Log"))
    end

    def log_error(log)
      execute_string(@formatter.reset.add_quoted_parameter(log).as_command("LogError"))
    end

    def log_error_expression(log)
      execute_string(@formatter.reset.add_parameter(log).as_command("LogError"))
    end

    #endregion

    # region Pointer Events
    # ******************************************************************************

    def click(object)
      click_event("Click", object)
    end

    def click_text(text)
      click_event_text("Click", text)
    end

    def double_click(object)
      click_event("DoubleClick", object)
    end

    def double_click_text(text)
      click_event_text("DoubleClick", text)
    end

    def right_click(object)
      click_event("RightClick", object)
    end

    def right_click_text(text)
      click_event_text("RightClick", text)
    end

    def move_to(object)
      click_event("MoveTo", object)
    end

    def move_to_text(text)
      click_event_text("MoveTo", text)
    end

    # endregion

    # region Mobile Gestures
    # ******************************************************************************

    def tap(object)
      click_event("Tap", object)
    end

    def tap_text(text)
      click_event_text("Tap", text)
    end

    def swipe_left(object=nil)
      swipe_event("Left", object)
    end

    def swipe_right(object=nil)
      swipe_event("Right", object)
    end

    def swipe_down(object=nil)
      swipe_event("Down", object)
    end

    def swipe_up(object=nil)
      swipe_event("Up", object)
    end

    def pinch_out(at_object=nil, to_object=nil)
      case at_object.class.to_s
        when "NilClass"
          pinch(false, false, nil, nil, nil)
        when "Point"
          if to_object
            pinch(false, false, at_object, nil, to_object)
          else
            pinch(false, false, at_object, nil, nil)
          end
        when "String"
          if to_object
            pinch(false, true, at_object, nil, to_object)
          else
            pinch(false, tru, at_object, nil, nil)
          end
      end
      nil
    end

    def pinch_in(at_object=nil, from_object=nil)
      case at_object.class
        when "NilClass"
          pinch(true, false, nil, nil, nil)
        when "Point"
          if from_object
            pinch(true, false, at_object, from_object, nil)
          else
            pinch(true, false, at_object, nil, nil)
          end
        when "String"
          if from_object
            pinch(true, true, at_object, from_object, nil)
          else
            pinch(true, true, at_object, nil, nil)
          end
      end
      nil
    end

    #endregion

    # region Mobile Device Control
    # ******************************************************************************

    def launch_app(app_name, device_name = nil)
      param = device_name ? "#{device_name}:#{app_name}" : app_name
      execute_string(@formatter.reset.add_quoted_parameter(param).as_command("LaunchApp"))
    end

    #endregion

    # region Image Searching
    # ******************************************************************************

    def image_info(image_name)
      execute_string(@formatter.reset.add_quoted_parameter(image_name).as_function("Return ImageInfo"))
      return @last_drive_result.as_array
    end

    def wait_for(image_name)
      execute_string(@formatter.reset.add_parameter(@image_search_timeout).add_quoted_parameter(image_name).as_command("WaitFor"))
    end

    def image_found(image_name)
      execute_string(@formatter.reset.add_parameter(@image_search_timeout).add_quoted_parameter(image_name).as_function("Return ImageFound"))
    end

    def every_image_location(image_name)
      execute_string(@formatter.reset.add_quoted_parameter(image_name).as_function("Return EveryImageLocation"))
    end

    #endregion

    # region Text
    # ******************************************************************************

    def type_text(text)
      execute_string(@formatter.reset.add_quoted_parameter(text).as_command("TypeText"))
      return @last_drive_result.return_value
    end

    def type_expression(expression)
      execute_string(@formatter.reset.add_parameter(expression).as_command("TypeText"))
      return @last_drive_result.return_value
    end

    def read_text(object)
      execute_string(@formatter.reset.add_parameter(object).add_plist_parameters(@text_search_options).as_function("ReadText"))
      return @last_drive_result.return_value
    end

    def remote_clipboard(timeout=nil)
      execute_string(@formatter.reset.add_parameter(timeout).as_function("RemoteClipboard"))
    end

    #endregion

    private

    # region Private Functions
    # ******************************************************************************

    def command_at_point(command, point)
      execute_string(@formatter.reset.add_parameter(point).as_command(command))
    end

    def command_at_image(command, image, timeout)
      formatter = @formatter.reset
      formatter.add_quoted_plist_parameter("Image", image)
      formatter.add_quoted_plist_parameter("WaitFor", timeout)
      execute_string(formatter.as_command(command))
    end

    def command_at_text(command, text, options)
      formatter = @formatter.reset
      formatter.add_quoted_plist_parameter("Text", text)
      formatter.add_plist_parameters(options)
      execute_string(formatter.as_command(command))
    end

    def click_event(type, object)
      case object.class.to_s
        when "Point"
          command_at_point(type, object)
        when "String"
          command_at_image(type, object, @image_search_timeout)
      end
      nil
    end

    def click_event_text(type, text)
      command_at_text(type, text, @text_search_options)
    end

    def swipe_event(direction, object=nil)
      case object.class.to_s
        when "NilClass"
          execute_string(@formatter.reset.as_command("Swipe#{direction}"))
        when "Point"
          command_at_point("Swipe#{direction}", object)
        when "String"
          command_at_image("Swipe#{direction}", object, @search_timeout)
      end
      nil
    end

    def pinch(pinch_in, images, pinch_at, pinch_from, pinch_to)
      formatter = @formatter.reset

      if images
        formatter.add_quoted_plist_parameter("At", pinch_at)
        formatter.add_quoted_plist_parameter("From", pinch_from)
        formatter.add_quoted_plist_parameter("To", pinch_to)
      else
        formatter.add_plist_parameter("At", pinch_at)
        formatter.add_plist_parameter("From", pinch_from)
        formatter.add_plist_parameter("To", pinch_to)
      end

      formatter.add_plist_parameter("Distance", @pinch_distance)
      formatter.add_plist_parameter("Duration", @pinch_duration)
      execute_string(formatter.as_command(pinch_in ? "PinchIn" : "PinchOut"))
    end

    #endregion

  end
end