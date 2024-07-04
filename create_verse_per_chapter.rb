
require 'fileutils'
require 'json'
require 'optparse'

require_relative 'util.rb'
require_relative 'book_contents.rb'

$prev_endtime = 0
$chapter_num = 1

def output_clip(file, title, file_path)
    #target_file = "#{File.join(File.dirname(file_path), File.basename(file_path, '.wav'))}.mp3"
    target_file = file_path
    puts "target_file: #{target_file}"

    # Version 2
    chap_num = $chapter_num.to_s
    chap_num = "0#{chap_num}" if chap_num.size == 1
    $chapter_num += 1

    res = %x(ffmpeg -i #{target_file} 2>&1 | grep "Duration")

    m = res.scan(/Duration: ([0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+),/)
    if m.empty? || m[0].empty?
        puts "failure"
        puts res
        exit 1
    end

    vid_duration = duration_to_ms(m[0][0])

    chapter_start = ms_to_duration($prev_endtime, 9)
    
    $prev_endtime += vid_duration
    
    chapter_end = ms_to_duration($prev_endtime, 9)

    file.puts("<ChapterAtom>")
    file.puts("<ChapterTimeStart>#{chapter_start}</ChapterTimeStart>")
    file.puts("<ChapterTimeEnd>#{chapter_end}</ChapterTimeEnd>")
    file.puts("<ChapterDisplay>")
    file.puts("<ChapterString>#{titleize(title)}</ChapterString>")
    file.puts("<ChapterLanguage>eng</ChapterLanguage>")
    file.puts("<ChapLanguageIETF>en</ChapLanguageIETF>")
    file.puts("</ChapterDisplay>")
    file.puts("<ChapterUID>#{generate_uid}</ChapterUID>")
    file.puts("</ChapterAtom>")
end

def init_output(file)
    file.puts('<?xml version="1.0"?>')
    file.puts('<!-- <!DOCTYPE Chapters SYSTEM "matroskachapters.dtd"> -->')
    file.puts('<Chapters>')
    file.puts('<EditionEntry>')
    file.puts('<EditionUID>2335985028171864315</EditionUID>')
end

def final_output(file)
    file.puts('</EditionEntry>')
    file.puts('</Chapters>')
end

# Creates a playlist for the contents of each chapter.
def create_playlist(book_name, data_infile, audio_infile, out_folder, ext='.wav')
    infile = "#{data_infile}#{book_name}.json"

    puts "audio_infile: #{audio_infile}"
    audio_in_path = "#{audio_infile}#{book_name}"

    jsonFile = File.open(infile)
    book = JSON.load(jsonFile)

    output_file = "#{out_folder}#{book_name}/douay_rheims_#{book_name}_chapter_mka"

    File.open("#{output_file}.txt", 'w:UTF-8') do |file|
        init_output(file)

        # Read content["title"], #{audio_in_path}/ch_#{index+1}/title
        puts "#{audio_in_path}/title#{ext}"
        output_clip(file, book["title"].join(" "), "#{audio_in_path}/title#{ext}")
        # file.puts("</ChapterAtom>")

        # Read content["intro"], #{audio_in_path}/ch_#{content["title"]}/intro
        if File.file?("#{audio_in_path}/intro#{ext}")
            output_clip(file, "#{book["title"].join(" ")} - Intro", "#{audio_in_path}/intro#{ext}")
            
            # file.puts("</ChapterAtom>")
        end

        final_output(file)
    end

    book["contents"].each_with_index do |content, index|

        puts "Chapter #{index + 1} / #{book["contents"].size}"

        File.open("#{output_file}_#{index+1}.txt", 'w:UTF-8') do |file|
            init_output(file)

            # Read content["title"], #{audio_in_path}/ch_#{index+1}/title
            puts "#{audio_in_path}/ch_#{index+1}/title#{ext}"
            output_clip(file, content["title"].join(" "), "#{audio_in_path}/ch_#{index+1}/title#{ext}")
            # file.puts("</ChapterAtom>")

            # Read content["intro"], #{audio_in_path}/ch_#{content["title"]}/intro
            if File.file?("#{audio_in_path}/ch_#{index+1}/intro#{ext}")
                output_clip(file, "#{content["title"].join(" ")} - Intro", "#{audio_in_path}/ch_#{index+1}/intro#{ext}")
                # file.puts("</ChapterAtom>")
            end


            content["contents"].sort_by { |k, v| k.to_i }.each do |k, verses|
                # Read verses, #{audio_in_path}/ch_#{content["title"]}/verse_#{k}
                puts "Verse #{k}/#{content["contents"].size}"
                output_clip(file, "#{book["title"].join(" ")} #{index + 1}:#{k}", "#{audio_in_path}/ch_#{index+1}/verse_#{k}#{ext}")

                # file.puts("</ChapterAtom>")
            end
            final_output(file)
        end
        $prev_endtime = 0
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
  # opt.on('--language [=LANGUAGE]') { |o| language = o }
end.parse!

FileUtils.mkdir_p File.dirname(out_folder)

skip = true
skip = false if target.nil?

BIBLE_STRUCTURE.each do |item|
    skip = false if item[:name] == target
    next if skip
    create_playlist(item[:name], data_infile, audio_inpath, out_folder, '.mp3')
    $prev_endtime = 0
end