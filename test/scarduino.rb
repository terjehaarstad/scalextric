require './load_lib.rb'

def setup_arduino_sp
  sp = SerialPort.new "/dev/ttyACM0"
  sp.baud = 19200
  sp.parity = SerialPort::NONE
  sp.read_timeout = 10
  sp.data_bits = 8
  sp.stop_bits = 1
  sp.sync = true
  sp

end
begin
  base = APB.new
  arduino = setup_arduino_sp
  base.enable_car(1)
  base.start_comms
  base.start_race
  base.run_car(1, 20)
  loop do
    str = arduino.read.chomp
    if not str.nil? and not str.empty?
      str = str.split ","
      id = str.first.to_i
      pin = str.last.to_i
      car = base.get_car(id)
      if pin.eql? 2 and id.eql? 1
        car.power = 28
      elsif pin.eql? 3 and id.eql? 1
        car.power = 21
        #car.brake = 1
      elsif pin.eql? 4 and id.eql? 1
        car.power = 30
      elsif pin.eql? 5 and id.eql? 1
        car.power = 0
      end
    end
  end
rescue Interrupt
  puts "Bye bye."
ensure
  arduino.close if arduino
  base.stop_comms
end
