#!/usr/bin/env ruby

require 'date'
require 'yaml'
require 'net/imap'
require 'getoptlong'

config_file = "imapshave.yml"

opts = GetoptLong.new(
  [ '--config', '-c', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when '--config'
      config_file = arg
    when '--help'
      puts "#{$0}: Purge email folders"
      puts "  --config/-c : YAML config file"
      exit 0
  end
end

begin
  @config = YAML.load_file config_file
rescue
  puts "ERROR: Config file not found or invalid, aborting"
  exit 1
end

begin
  imap = Net::IMAP.new(@config[:server], :ssl => @config[:ssl])
  imap.login(@config[:user], @config[:pass])
rescue Exception => e
  puts "ERROR: #{e.message}"
  exit 1
end

@config[:folders].each do |folder, conf|
  imap.select(folder)
  expiry_date = (Date.today - conf[:keep]).strftime("%d-%b-%Y")

  # get messages older than <expiry> days
  messages = imap.search(["BEFORE", expiry_date])
  next if messages.count == 0

  # check for flagged messages
  if conf[:skip_flagged]
    flagged = []
    imap.fetch(messages, ["FLAGS"]).each do |data|
      flagged << messages.delete(data.seqno) if data.attr["FLAGS"].include?(:Flagged)
    end
  end

  msg = "#{messages.count} messages to delete in folder #{folder}"
  msg << " (#{flagged.count} skipped)" if conf[:skip_flagged]
  puts msg
  print "Proceed ? (y/N): "

  if STDIN.gets.chomp =~ /^y$/i
    # delete messages
    imap.store(messages, "+FLAGS", :Deleted)
    imap.expunge
  else
    puts "Skipping folder #{folder}"
  end
end

imap.logout
imap.disconnect
