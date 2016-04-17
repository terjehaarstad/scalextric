#encoding: BINARY
module Scalextric

  # Car holds information about car brakes, lane-changes, speed
  # and lap time and holds 1 byte of data. Car is the parent class of 
  # Handset which is wrapped into the response received from APB.
  # Power, lane-change and brakes can be activated either by passing a 
  # Integer or as binary data.
  #
  # Example:
  #   car1 = Car.new
  #   car1.power = "\x7F"
  #   car1.power = 63
  #   car1.lane = 1
  #   car1.break = 1
  class Car
    attr_reader :id
    attr_accessor :brake, :lane, :power, :lap_time
    
    # Returns a fully populated Car object based on a byte given as 
    # argument. #read complements the byte received with one.
    def self.read(byte, id = 0 )
      if not byte.nil? and byte.size.eql? 1
        byte = Packet.force_binary(byte)
        id = id
        c = self.new(id)
        c.power = byte
        # Although very unlikely ensure we don't set car break and lane if we do the magic of pushing
        # throttle to 1.
        if byte.ord > 1
          c.lane = byte 
          c.brake = byte
        end
        c
      end
    end
    
    # Initialize a new car intance. Default ID is 0.
    def initialize(car_id = 0)
      @id = car_id
      self.brake = 0  # 0 = brake off, 128 = brake on.
      self.lane = 0   # 0 = Do not change lane, 64 = Change lane.
      self.power = 0  # 0 = stop, 63 = full speed.
    end
    
    # Set car power, 0-63. 
    def power=(num)
      return @power = num.ord & 0b00111111
    end
    
    # Enable or disable lane change.
    def lane=(num)
      num = num.ord
      return @lane = 64 if (num & 0b01000000).eql? 64 or num.eql? 1
      return @lane = 0
    end
    
    # Enable or disable breaks.
    def brake=(num)
      num = num.ord
      return @brake = 128 if (num & 0b10000000).eql? 128 or num.eql? 1
      return @brake = 0
    end
    
    # Returns attributes to string.
    def to_s
      (@brake + @lane + @power).chr
    end
  end
end
