require 'xmlrpc/client'
require_relative './drive_result'
require_relative './egg_drive_exception'

class EggDrive
  module RpcConnector
    attr_reader :last_drive_result
    # classes including this module must instantiate @connection_state

    class ConnectionState
      attr_reader :level
      NOT_CONNECTED = 0
      CONNECTED = 1
      IN_SESSION = 2

      def initialize(state=NOT_CONNECTED)
        @level = state
      end

      def is_at_least?(connection_state)
        @level >= connection_state
      end

      def is_below?(connection_state)
        @level < connection_state
      end

      def is?(connection_state)
        @level == connection_state
      end
    end

    def connect_drive(address, port)
      if @connection_state.is_at_least?(ConnectionState::CONNECTED)
        STDERR.puts "Tried to connect, but connection is already established"
        @connection_state = ConnectionState.new(ConnectionState::NOT_CONNECTED)
        return false
      end

      begin
        @client = XMLRPC::Client.new(address, nil, port)
      rescue => e
        @connection_state = ConnectionState.new(ConnectionState::NOT_CONNECTED)
        return false
      end

      @connection_state = ConnectionState.new(ConnectionState::CONNECTED)
      return true
    end

    def disconnect_drive
      if @connection_state.is_below?(ConnectionState::CONNECTED)
        STDERR.puts("Tried to disconnect, but not connected")
        return false
      end

      if @connection_state.is_at_least?(ConnectionState::IN_SESSION)
        end_drive_session
      end

      @connection_state = ConnectionState.new(ConnectionState::CONNECTED)

      @client = nil

      @connection_state = ConnectionState.new(ConnectionState::NOT_CONNECTED)

      return true
    end

    def start_drive_session(session)
      if @connection_state.is_at_least?(ConnectionState::IN_SESSION)
        STDERR.puts("Tried to start a session, but session already exists")
        return false
      elsif @connection_state.is?(ConnectionState::NOT_CONNECTED)
        STDERR.puts("Tried to start a session, but not connected")
        return false
      end

      begin
        @client.call('StartSession', session)
      rescue XMLRPC::FaultException => e
        if @override_previous_session && e.faultCode == 2
          end_drive_session(true)
          retry
        else
          STDERR.puts("Could not start session #{session}: #{e.faultCode}-#{e.faultString}")
        end
      end

      @connection_state = ConnectionState.new(ConnectionState::IN_SESSION)
      return true
    end

    def end_drive_session(force=false)
      if @connection_state.is_below?(ConnectionState::IN_SESSION) && !force
        STDERR.puts("Tried to end a session, but not in session")
        return false
      end

      begin
        @client.call("EndSession", [])
      rescue XMLRPC::FaultException => e
        STDERR.puts("Session could not be ended")
        return false
      end

      @connection_state = ConnectionState.new(ConnectionState::CONNECTED)
      return true
    end

    def execute_string(command)
      if @connection_state.is_below?(ConnectionState::IN_SESSION)
        STDERR.puts("Tried to execute a command while not in session")
        return false
      end

      begin
        ret = @client.call("Execute", command)
        @last_drive_result = DriveResult.new_success(ret["Output"],ret["Duration"],ret["ReturnValue"],ret["Result"])
      rescue XMLRPC::FaultException => e
        @last_drive_result = DriveResult.new_error(e.faultCode, e.faultString)
        raise EggDriveException.new(e.faultCode, e.faultString)
      end
    end

  end
end