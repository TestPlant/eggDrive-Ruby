class EggDrive
  class EggDriveException < StandardError
    attr_reader :fault_code

    module FaultCode
      NO_ERROR =0
      UNKNOWN_METHOD = 1
      SESSION_BUSY = 2
      NO_ACTIVE_SESSION = 3
      EXCEPTION = 4
      SESSION_SUITE_FAILURE = 5
      UNKNOWN_FAULT = -1
    end


    def initialize(fault_code, message)
      super(message)
      if fault_code >= FaultCode::NO_ERROR && fault_code <= FaultCode::SESSION_SUITE_FAILURE
        @fault_code = fault_code
      else
        @fault_code = FaultCode::UNKNOWN_FAULT
      end
    end

  end
end