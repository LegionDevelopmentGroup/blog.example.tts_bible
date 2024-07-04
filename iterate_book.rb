
require 'fileutils'
require 'json'
require 'optparse'

require_relative 'util.rb'
require_relative 'book_contents.rb'

def read_book(text, ref, book_name, index, bitrate='16k', ext = '.wav')
    book_path = ref
    index_path = ""
    ch_path = "_intro"
    if !index.nil?
        index_path = "_#{index}"
        ch_path = "_ch#{index}"
    else
        index_path = ""
        ch_path = "_intro"
    end

    if !File.file?("#{book_path}/douay_rheims_#{book_name}#{index_path}.mka")
        run_cmd do
            %x(ffmpeg -f concat -safe 0 -i #{book_path}/douay_rheims_#{book_name}_filelist#{index_path}.txt -c copy #{book_path}/douay_rheims_#{book_name}#{index_path}.mka)
        end
    else
        puts "File exists: #{book_path}/douay_rheims_#{book_name}#{index_path}.mka"
    end

#    target_file = "#{File.join(File.dirname(ref), File.basename(ref, '.wav'))}.mp3"
    
    if !File.file?("#{book_path}/douay_rheims_#{book_name}#{ch_path}.mka")
        run_cmd do
            %x(mkvmerge -o #{book_path}/douay_rheims_#{book_name}#{ch_path}.mka --chapters #{book_path}/douay_rheims_#{book_name}_chapter_mka#{index_path}.txt #{book_path}/douay_rheims_#{book_name}#{index_path}.mka)
        end
    else
        puts "File exists: #{book_path}/douay_rheims_#{book_name}#{ch_path}.mka"
    end

    # puts "ffmpeg -i #{book_path}/douay_rheims_#{book_name}#{ch_path}.mka -map 0 -c:a libopus -b:a #{bitrate} -c:s copy -y #{book_path}/douay_rheims_#{book_name}#{ch_path}.min.mka"
    if !File.file?("#{book_path}/douay_rheims_#{book_name}#{ch_path}.min.mka")
        run_cmd do
            %x(ffmpeg -i #{book_path}/douay_rheims_#{book_name}#{ch_path}.mka -map 0 -c:a libopus -b:a #{bitrate} -c:s copy -y #{book_path}/douay_rheims_#{book_name}#{ch_path}.min.mka)
        end
    else
        puts "File exists: #{book_path}/douay_rheims_#{book_name}#{ch_path}.min.mka"
    end
end

def read_book_path(book_name,
    in_folder_path,
    out_folder_path)
    infile = "#{in_folder_path}#{book_name}.json"
    out_folder = "#{out_folder_path}#{book_name}"

    file = File.open(infile)
    book = JSON.load(file)

    FileUtils.mkdir_p out_folder

    puts "Title #{book_name}"

    read_book(book["title"], out_folder, book_name, nil)

    book["contents"].each_with_index do |content, index|

        puts "Chapter #{index + 1} / #{book["contents"].size}"

        read_book(content["title"], out_folder, book_name, index+1)
    end
end

skip = true
target = nil
in_path = 'data/douay_rheims_'
out_path = 'audio_out/'

OptionParser.new do |opt|
  opt.on('--inpath [=INPUT_PATH]') { |o| in_path = o }
  opt.on('--outpath [=OUTPUT_PATH]') { |o| out_path = o }
  opt.on('--target [=TARGET]') { |o| target = o }
end.parse!

FileUtils.mkdir_p File.dirname(out_path)

skip = true
skip = false if target.nil?

BIBLE_STRUCTURE.each do |book|
    skip = false if book[:name] == target
    next if skip
    read_book_path(book[:name], in_path, out_path)
end