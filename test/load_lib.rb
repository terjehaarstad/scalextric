$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../lib'))

require 'snc.rb'
include Scalextric

# typical data sent from APB.
out_stream = "\x83\xFF\x7F\x7F\x7F\x7F\x7F\x00\xF8\x02\x00\x00\x00\xFF\xF9".force_encoding "BINARY"
# typical data sent to APB.
in_stream  = "\xff\xff\xff\xff\xff\xff\xff\x80\xad".force_encoding "BINARY"
