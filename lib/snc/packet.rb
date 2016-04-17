#encoding: BINARY
module Scalextric

  # Packet is the parent class of both InPacket and OutPacket. It will act 
  # as an abstract class to give subclasses basic functions. Users usually 
  # want to interact with any other packets than this directly.
  class Packet
    attr_accessor :data # Holds binary string.
    attr_accessor :crc  # Packet checksum value.
    
    # Take a byte and swap bits with one complement.
    def self.ones_complement(byte)
      if not byte.nil? and not byte.empty?
        byte = Packet.force_binary(byte).ord
        [~byte & 0xFF].first.chr
      end
    end
    
    # Force string into binary data.
    def self.force_binary(str)
      str.force_encoding("BINARY") if str.respond_to? :force_encoding
    end
    
    # Creates a new Packet instance.
    def initialize
      @data = "\x00" * 8 # Dummy data
      @crc = 0
    end
    
    # Recalculates the packets and returns a binary string which is ready to
    # be sent on tze wire.
    def to_s
      recalc
      @data + @crc.chr
    end
    
    # Return calculated CRC code.
    def crc
      recalc
      @crc
    end
     
    # Recalc crc and return result.
    def recalc
      @crc = CRC8.calculate(@data)
    end
    
    # Returns packet size.
    def size
      self.to_s.size
    end
  end
end
