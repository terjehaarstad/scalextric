#encoding: BINARY
module Scalextric

  # An InPacket is typically sent to the Advanced Power Base and is 9 bytes in 
  # size. This class is usually not called directly, since APB-class is used
  # to handle communications to the APB. An InPacket instance holds 6-car-objects
  # in an array called "drive_packets", which can be manipulated directly.
  #
  # In-packet carries information for:
  #   1. Driving signal for each car.
  #   2. Driving signal for each LED on 6CPB unit.
  #
  # Packet Structure:
  #    1st byte - Operation_mode
  #    2nd byte - Drivepacket #1
  #    3rd byte - Drivepacket #2
  #    4th byte - Drivepacket #3
  #    5th byte - Drivepacket #4
  #    6th byte - Drivepacket #5
  #    7th byte - Drivepacket #6
  #    8th byte - LED-status. 
  #    9th byte - Checksum (CRC8)
  class InPacket < Packet
    attr_accessor :op_mode,       # Usually 0xFF. 0x7F if not...
                  :drive_packets, # Array which holds 6 Car-objects.
                  :led_status     # APB LED status.
  
    # Returns a populated InPacket object based on binary string given as 
    # argument.
    #def self.read(str)
    #  str = InPacket.force_binary(str)
    #  if InPacket.is_inpkt?(str)
    #    pkt = InPacket.new
    #    pkt.op_mode = str[0].ord
    #    pkt.drive_packets = []
    #    6.times { |i| pkt.drive_packets << Car.read(str[i+1], i+1) }
    #    pkt.led_status = str[7].ord
    #    pkt.crc = str[8].ord
    #    pkt
    #  end
    #end
    
    # Returns true if string given as argument is InPacket.
    def self.is_inpkt?(str)
      str = Packet.force_binary(str)
      return true if str.size.eql? 9 and (str[0].ord.eql? 255 or str[0].ord.eql? 127) 
      return false
    end
    
    def initialize
      super
      @op_mode = 255
      @drive_packets = []
      @led_status = 192  # Green and Red LED enabled as default.
      6.times { |i| @drive_packets << Car.new(i+1) }
    end
    
    # Updates data attribute and crc.
    def recalc
      @data = @op_mode.chr
      drive_packets.each { |car| @data += InPacket.ones_complement(car.to_s) }
      @data += @led_status.chr
      @crc = CRC8.calculate(@data)
    end
  end

  # OutPacket class is the packets received from the APB. As of firmware 0.82
  # it is 15 bytes in size. OutPacket class method :read is usually used when
  # an binary stream is received on the slave, but an empty OutPacket instance
  # might be created if your up for some crazy shit...
  #
  # Out-packet carries information for:
  #   1. Current status of each handset.
  #   2. Auxiliary port current consumed.
  #   3. Game Timer information.
  #   4. Car information updated.
  #
  # Packet structure:
  #   1st byte - Handset and Track Status.
  #   2nd byte - Handset #1
  #   3rd byte - Handset #2
  #   4th byte - Handset #3
  #   5th byte - Handset #4
  #   6th byte - Handset #5
  #   7th byte - Handset #6
  #   8th byte - Aux Port Current.
  #   9th byte - Car ID / Track # Updated.
  #   10th byte - Game or SF-line. (LSB first)
  #   11th byte - Game or SF-line.
  #   12th byte - Game or SF-line.
  #   13th byte - Game or SF-line. (MSB first)
  #   14th byte - Button Status.
  #   15th byte - Checksum. 
  class OutPacket < Packet
    attr_accessor :handset_track_status, :handsets, 
                  :aux_port_current, :car_track_id, 
                  :sf_time, :button_status
    
    class Handset < Car; end
    
    # Populate received data into the object.
    def self.read(str)
      str = OutPacket.force_binary(str)
      if OutPacket.is_outpkt?(str)
        pkt = OutPacket.new
        pkt.data = str[0..-2]
        pkt.handset_track_status = str[0].ord
        pkt.handsets =  []
        pkt.aux_port_current = str[7].ord
        pkt.car_track_id = str[8].ord
        pkt.sf_time = str[9..12].reverse 
        pkt.button_status = str[13].ord
        pkt.crc = str[14].ord
        6.times { |i| pkt.handsets << Handset.read(Packet.ones_complement(str[i+1]), i+1) }
        raise "CRC8 OutPacket Missmatch." if not CRC8.calculate(str).eql? pkt.crc
        pkt
      end
    end
    
    # Returns true if string is 15.
    def self.is_outpkt?(str)
      return true if not str.nil? and str.size.eql? 15 and str.ord > 128
      return false
    end
    
    def initialize
      @handset_track_status = 0
      @handsets = []
      6.times { |i| @handsets << Handset.new(i+1) }
      @aux_port_current = 0
      @car_track_id = 0
      @sf_time = "\x00\x00\x00\x00"
      @button_status = 0
      @crc = 0
    end
    
    # Return binary string.
    def to_s
      recalc
      @data+@crc.chr
    end
    
    # Recalculate crc code.
    def recalc
      @data = @handset_track_status.chr
      @handsets.each { |car| @data += OutPacket.ones_complement(car.to_s) }
      @data += @aux_port_current.chr
      @data += @car_track_id.chr
      @data += @sf_time.reverse
      @data += @button_status.chr
      @crc = CRC8.calculate(@data+@crc.chr)
    end
  end
end
