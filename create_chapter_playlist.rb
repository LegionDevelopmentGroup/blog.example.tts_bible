
require 'fileutils'
require 'json'
require 'optparse'

require_relative 'util.rb'
require_relative 'book_contents.rb'

def output_clip(file, title, file_path)
    target_file = "#{File.join(File.dirname(file_path), File.basename(file_path, '.wav'))}.mp3"

    # Create file list
    file.puts("file '#{target_file}'")
end

# Creates a playlist for the contents of each chapter.
def create_playlist(book_name, data_infile, audio_infile, out_folder)
    jsonFile = File.open(data_infile)
    book = JSON.load(jsonFile)

    FileUtils.mkdir_p("#{out_folder}#{book_name}")

    output_file = "#{out_folder}#{book_name}/douay_rheims_#{book_name}_filelist"

    File.open("#{output_file}.txt", 'w:UTF-8') do |file|
        output_clip(file, book["title"].join(" "), "#{audio_infile}/title.wav")

        if File.file?("#{audio_infile}/intro.wav")
            output_clip(file, "#{book["title"].join(" ")} - Intro", "#{audio_infile}/intro.wav")
        end
    end

    book["contents"].each_with_index do |content, index|

        puts "Chapter #{index + 1} / #{book["contents"].size}"

        File.open("#{output_file}_#{index+1}.txt", 'w:UTF-8') do |file|

            # Read content["title"], #{audio_infile}/ch_#{index+1}/title
            output_clip(file, content["title"].join(" "), "#{audio_infile}/ch_#{index+1}/title.wav")

            # Read content["intro"], #{audio_infile}/ch_#{content["title"]}/intro
            if File.file?("#{audio_infile}/ch_#{index+1}/intro.wav") || File.file?("#{audio_infile}/ch_#{index+1}/intro.mp3")
                output_clip(file, "#{content["title"].join(" ")} - Intro", "#{audio_infile}/ch_#{index+1}/intro.wav")
            end

            content["contents"].sort_by { |k, v| k.to_i }.each do |k, verses|
                # Read verses, #{audio_infile}/ch_#{content["title"]}/verse_#{k}
                puts "Verse #{k}/#{content["contents"].size}"
                output_clip(file, "#{book["title"].join(" ")} #{index + 1}:#{k}", "#{audio_infile}/ch_#{index+1}/verse_#{k}.wav")
            end
        end
    end
end

data_infile = 'douay_rheims_'
audio_inpath = 'audio_out/'
out_folder = 'tmp/'
target = nil

OptionParser.new do |opt|
  opt.on('--data_inpath [=DATA_INPUT_PATH]') { |o| data_infile = o }
  opt.on('--audio_inpath [=AUDIO_INPUT_PATH]') { |o| audio_inpath = o }
  opt.on('--outpath [=OUTPUT_PATH]') { |o| out_folder = o }
  opt.on('--target [=TARGET]') { |o| target = o }
  opt.on('--language [=LANGUAGE]') { |o| language = o }
end.parse!

FileUtils.mkdir_p File.dirname(out_folder)

skip = true
skip = false if target.nil?

BIBLE_STRUCTURE.each do |item|
    skip = false if item[:name] == target
    next if skip
    create_playlist(item[:name], "#{data_infile}#{item[:name]}.json", "#{audio_inpath}#{item[:name]}", out_folder)
end