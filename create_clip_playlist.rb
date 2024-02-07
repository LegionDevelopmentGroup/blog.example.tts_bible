
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
def create_playlist(book_name, data_in_folder_path, tmp_path)
    infile = "#{data_in_folder_path}#{book_name}.json"

    jsonFile = File.open(infile)
    book = JSON.load(jsonFile)

    offset = 1

    output_file = "#{tmp_path}#{book_name}/douay_rheims_#{book_name}.m3u"

    File.open(output_file, 'w:UTF-8') do |file|
        init_output(file)

        # iterate through the book and create the playlist
        output_clip(file, book["title"].join(" "), "title.mp3", offset)
        offset += 1
        output_clip(file, "Introduction", "intro.mp3", offset)
        offset += 1

        book["contents"].each_with_index do |content, index|

            puts "Chapter #{index + 1} / #{book["contents"].size}"

            output_clip(file, content["title"].join(" "), "ch_#{index+1}/title.mp3", offset)
            offset += 1

            # Read content["intro"], ch_#{content["title"]}/intro
            output_clip(file, "#{content["title"].join(" ")} - Intro", "ch_#{index+1}/intro.mp3", offset)
            offset += 1

            # file.puts("</ChapterAtom>")

            content["contents"].sort_by { |k, v| k.to_i }.each do |k, verses|
                # Read verses, ch_#{content["title"]}/verse_#{k}
                puts "Verse #{k}/#{content["contents"].size}"
                output_clip(file, "#{book["title"].join(" ")} #{index + 1}:#{k}", "ch_#{index+1}/verse_#{k}.mp3", offset)
                offset += 1

                # file.puts("</ChapterAtom>")
            end
        end

        final_output(file)
    end
end

skip = true
target = nil # 'kings_3'
data_in_path = 'data/douay_rheims_'
out_path = 'tmp/'

OptionParser.new do |opt|
  opt.on('--data_inpath [=DATA_INPUT_PATH]') { |o| data_in_path = o }
  opt.on('--outpath [=OUT_PATH]') { |o| out_path = o }
end.parse!

FileUtils.mkdir_p File.dirname(out_path)

skip = false if target.nil?

OLD_TESTAMENT_STRUCTURE.each do |item|
    skip = false if item[:name] == target
    next if skip
    create_playlist(item[:name], data_in_path, out_path)
    # break
end