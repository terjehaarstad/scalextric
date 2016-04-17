#encoding: BINARY
require 'serialport'
module Scalextric
  # APB class is the interface which users usually interacts with for 
  # controlling of the base. An APB instance is initiated with a com_port 
  # argument, which default is set to "/dev/ttyUSB0". 
  #
  # Communication with the base is started with instance-method #start_comms 
  # which will create a new "communication" thread. It will continously send and 
  # receive In- and Out-Packets, which is held in each APB-instance read-only
  # attribute #in_packet and #out_packet. Cars can be updated directly by 
  # calling APB#run_car(ID, SPEED) and is wrapped into an InPacket and sent 
  # on the wire. A race is started by using #start_race.
  #
  # Example:
  # base = APB.new
  # base.start_comms
  # base.start_race
  # base.run_car(1, 30)
  class APB
    attr_reader :in_packet     # InPacket is sent to APB.
    attr_reader :out_packet    # OutPacket is received from APB.
    attr_reader :cars          # Array which holds 6 cars.
    
    def initialize(com_port = "/dev/ttyUSB0")
      @out_packet = OutPacket.new  # Packet received from the base.
      @in_packet = InPacket.new    # Packet sent to the base.
      @serial_port = SerialPort.new(com_port)
      @serial_port.read_timeout = 1
      @serial_port.baud = 19200
      @serial_port.data_bits = 8
      @serial_port.stop_bits = 1
      @serial_port.parity = SerialPort::NONE
      @serial_port.sync = true
      @connection_status = false
      @race_status = false
      @cars = []
      6.times { |i| @cars << @in_packet.drive_packets[i] }
    end
    
    # Start communication thread with Base.
    def start_comms
      if not @connection_status
        begin
          @connection_status = true
          coms_thread
        end
      end
    end
    
    # Stop communication thread with base.
    def stop_comms
      if @connection_status
        @connection_status = false
        Thread.kill @thread
      end
    end
    
    # Start race
    def start_race
      if @connection_status
        @race_status = true
        disable_red_led
      else
        raise "Could not start race: Not connected to APB."
      end
    end
    
    # Stop race
    def stop_race
      if @race_status
        @race_status = false
        enable_red_led
      end
    end
    
    # Set Car speed.
    def run_car(car_id, power)
      get_car(car_id).power = power
    end
    alias_method :car_speed, :run_car
    
    # Break car.
    def enable_break(car_id)
      get_car(car_id).break = 128
    end
    
    # Disable break.
    def disable_break(car_id)
      get_car(car_id).break = 0
    end
    
    # Enable Car lane change.
    def enable_lane_change(car_id)
      get_car(car_id).lane = 64
    end
    
    # Disable Car change lane.
    def disable_lane_change(car_id)
      get_car(car_id).lane = 0
    end
    
    # Return Car based on car id.
    def get_car(car_id)
      @cars[car_id-1]
    end
    
    # Returns seconds since race started.
    def run_time
      get_counter
    end
    alias_method :race_time, :run_time
    
    # Enable car/track LED on APB.
    def enable_car(car)
      enable_car_led(car)
    end
    
    # Disable car/track LED on APB.
    def disable_car(car)
      disable_car_led(car)
    end

    # Private nudie area.
    private
    
    # Returns calculated start-finish time.
    def get_counter
      pkt = @out_packet
      if pkt and pkt.sf_time
        counter = pkt.sf_time.unpack("N*").first
        counter = (((counter * 6.4) / 1000) / 1000).round(3)
      end
    end
    
    # Thread communications.
    def coms_thread
      @thread = Thread.new do
        loop do
          write_read_packet         
          sleep 0.03
        end
      end
    end
    
    # Write a packet and read a reponse to complete a cycle.
    def write_read_packet
      write_packet
      read_packet
    end
    
    # Recalc InPacket and send to APB.
    def write_packet
      @in_packet.recalc
      @serial_port.write @in_packet.to_s
    end
    
    # Read packet from APB and populate OutPacket.
    def read_packet
      @out_packet = OutPacket.read(@serial_port.read(15))
    end

    # Enable car / track.
    def enable_car_led(car_id)
      if car_id.eql? 1 and not (@in_packet.led_status & 0b00000001).eql? 1
        @in_packet.led_status += 0b00000001
      elsif car_id.eql? 2 and not (@in_packet.led_status & 0b00000010).eql? 2 
        @in_packet.led_status += 0b00000010
      elsif car_id.eql? 3 and not (@in_packet.led_status & 0b00000100).eql? 4
        @in_packet.led_status += 0b00000100
      elsif car_id.eql? 4 and not (@in_packet.led_status & 0b00001000).eql? 8
        @in_packet.led_status += 0b00001000
      elsif car_id.eql? 5 and not (@in_packet.led_status & 0b00010000).eql? 16
        @in_packet.led_status += 0b00010000
      elsif car_id.eql? 6 and not (@in_packet.led_status & 0b00100000).eql? 32
        @in_packet.led_status += 0b00100000
      end
    end
    
    # Disable car / track.
    def disable_car_led(car_id)
      if car_id.eql? 1 and (@in_packet.led_status & 0b00000001).eql? 1
        @in_packet.led_status -= 0b00000001
      elsif car_id.eql? 2 and (@in_packet.led_status & 0b00000010).eql? 2
        @in_packet.led_status -= 0b00000010
      elsif car_id.eql? 3 and (@in_packet.led_status & 0b00000100).eql? 4
        @in_packet.led_status -= 0b00000100
      elsif car_id.eql? 4 and (@in_packet.led_status & 0b00001000).eql? 8
        @in_packet.led_status -= 0b00001000
      elsif car_id.eql? 5 and (@in_packet.led_status & 0b00010000).eql? 16
        @in_packet.led_status -= 0b00010000
      elsif car_id.eql? 6 and (@in_packet.led_status & 0b00100000).eql? 32
        @in_packet.led_status -= 0b00100000
      end
    end
    
    # Enable Green LED.
    def enable_green_led
      if not (@in_packet.led_status & 0b10000000).eql? 128
        @in_packet.led_status += 0b10000000
      end
    end
    
    # Disable Green LED.
    def disable_green_led
      if (@in_packet.led_status & 0b10000000).eql? 128
        @in_packet.led_status -= 0b10000000
      end
    end
    
    # Enable Red LED.
    def enable_red_led
      if not (@in_packet.led_status & 0b01000000).eql? 64
        @in_packet.led_status += 0b01000000
      end
    end
    
    # Disable Red LED.
    def disable_red_led
      if (@in_packet.led_status & 0b01000000).eql? 64
        @in_packet.led_status -= 0b01000000
      end
    end
  end
end
