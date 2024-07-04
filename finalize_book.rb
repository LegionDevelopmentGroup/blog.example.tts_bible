
require 'fileutils'
require 'json'
require 'optparse'

require_relative 'util.rb'
require_relative 'book_contents.rb'

def finish_bible_path(book_name,
    data_in_path,
    audio_in_path,
    out_folder_path,
    tmp_folder)
    infile = "#{data_in_path}#{book_name}.json"
    out_folder = "#{out_folder_path}#{book_name}"

    file = File.open(infile)
    book = JSON.load(file)

    tmp_path = "#{tmp_folder}#{book_name}/"

    FileUtils.mkdir_p tmp_path
    FileUtils.mkdir_p out_folder


    run_cmd do
        %x(cp #{tmp_path}douay_rheims_#{book_name}_intro.min.mka #{out_folder}/douay_rheims_#{book_name}_intro.mka)
    end

    run_cmd do
        %x(cp #{tmp_path}douay_rheims_#{book_name}_ch*.min.mka #{out_folder}/)
    end

    run_cmd do
        puts "rename 's/.min.mka$/.mka/' #{out_folder}/douay_rheims_#{book_name}_ch*.min.mka"
        %x(rename 's/.min.mka$/.mka/' #{out_folder}/douay_rheims_#{book_name}_ch*.min.mka)
    end

    run_cmd do
        %x(cp #{tmp_path}*.m3u #{out_folder}/)
    end
end

skip = true
target = nil # 'kings_3'
data_in_path = 'data/douay_rheims_'
audio_in_path = 'audio_out/'
out_path = 'out/douay_rheims/'
tmp_folder = 'tmp/'

OptionParser.new do |opt|
  opt.on('--data_inpath [=DATA_INPUT_PATH]') { |o| data_in_path = o }
  opt.on('--audio_inpath [=AUDIO_INPUT_PATH]') { |o| audio_in_path = o }
  opt.on('--outpath [=OUTPUT_PATH]') { |o| out_path = o }
  opt.on('--tmppath [=TMP_PATH]') { |o| tmp_folder = o }
  opt.on('--target [=TARGET]') { |o| target = o }
end.parse!

FileUtils.mkdir_p File.dirname(out_path)

skip = true
skip = false if target.nil?

BIBLE_STRUCTURE.each do |book|
    puts "book[:name]: #{book[:name]}"
    puts "target: #{target}"
    puts "skip : #{skip}"
    skip = false if book[:name] == target
    next if skip
    finish_bible_path(book[:name], data_in_path, audio_in_path, out_path, tmp_folder)
end