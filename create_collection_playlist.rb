
require 'fileutils'
require 'json'
require 'optparse'

require_relative 'util.rb'
require_relative 'book_contents.rb'

def output_clip(file, title, file_path, offset)
    # # Create m3u playlist
    file.puts("#EXTINF:#{offset},#{title}") # internal stuff + display name
    file.puts(file_path) # path
end

def init_output(file)
    # for m3u playlist
    file.puts('#EXTM3U')
end

def final_output(file)
end

# For the entire book creates a playlist by expecting there to be a single file per chapter
def create_playlist(file, book_name, tmp_path, offset)
    output_clip(file, book_name, "#{tmp_path}#{book_name}/douay_rheims_#{book_name}.m3u", offset)
end

skip = true
target = nil # 'kings_3'
out_path = 'tmp/douay_rheims.m3u'

OptionParser.new do |opt|
  opt.on('--outpath [=OUT_PATH]') { |o| out_path = o }
end.parse!

FileUtils.mkdir_p File.dirname(out_path)

skip = false if target.nil?

# Truncate the file
File.open(out_path, 'w') do |file|
    init_output(file)

    offset = 1
    OLD_TESTAMENT_STRUCTURE.each do |item|
        skip = false if item[:name] == target
        next if skip
        create_playlist(file, item[:name], '', offset)
        break if item[:name] == 'deuteronomy'
        offset += 1
    end
    final_output(file)
end