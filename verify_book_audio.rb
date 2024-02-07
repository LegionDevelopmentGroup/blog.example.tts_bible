
require 'fileutils'
require 'json'
require 'optparse'

require_relative 'util.rb'
require_relative 'book_contents.rb'

VIDEO_ISSUE_THRESHOLD = 3

def normalize_text(text)
    text.gsub(/[[:punct:]]/, '').downcase.strip
end

def valid_clip?(text, segments, clip_length, threshold)
    return false if segments.empty?

    previous_end_time = 0
    segments.each do |segment|
        if segment['start'] - threshold >= previous_end_time
            # Handle invalid preceding audio
            return false
        end

        previous_end_time = segment['end']
    end

    if segments[-1]['end'] + threshold <= clip_length
        # Handle invalid clip
        return false
    end
    return true
end

def read_book(text, ref, lang, ext = '.wav')
    # Call tts function with given text

    target_file = "#{File.join(File.dirname(ref), File.basename(ref, ext))}.mp3"
    out_dir = File.dirname(ref)

    if !File.file?(target_file)
        # File doesn't exist
        puts "File not found #{target_file}"
        exit 1
    end

    file_path = File.join(out_dir, "#{File.basename(ref, ext)}.json")

    if !File.file?(file_path) 
        run_cmd do
            %x(~/.local/bin/whisper #{target_file} --language #{lang} --output_dir #{out_dir} --output_format json)
        end
    end

    res = %x(ffmpeg -i #{target_file} 2>&1 | grep "Duration")

    m = res.scan(/Duration: ([0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+),/)
    if m.empty? || m[0].empty?
        puts "failure"
        puts res
        exit 1
    end

    vid_duration = duration_to_ms(m[0][0]).to_f / 1000.0

    file = File.open(file_path)
    sub_details = JSON.load(file)

    detail = normalize_text(text.join(' '))
    sub_text = normalize_text(sub_details["text"])


    timings = sub_details["segments"].map do |seg|
        {
            start: seg['start'],
            end: seg['end']
        }
    end

    item = {
        path: ref,
        raw_text_nom: detail,
        whisper_nom: sub_text,
        timing_issue: !valid_clip?(detail, sub_details["segments"], vid_duration, VIDEO_ISSUE_THRESHOLD),
        total_clip_length: vid_duration,
        text_match: detail == sub_text,
        timings: timings,
    }


    if detail != sub_text
        puts "Text: #{detail}"
        puts "Subt: #{sub_text}"
        puts "Audio subtitle does not match #{ref}"
    end

    return item
end

def read_book_path(book_name,
    data_in_folder_path,
    audio_in_folder_path,
    out_folder_path,
    lang)
    #book_name = 'genesis'
    infile = "#{data_in_folder_path}#{book_name}.json"

    verify_file = "#{out_folder_path}#{book_name}_verify.json"
    out_folder = "#{audio_in_folder_path}#{book_name}"

    file = File.open(infile)
    book = JSON.load(file)

    FileUtils.mkdir_p out_folder

    valid_details = []

    puts "Title"
    # Read book["title"], #{out_folder}/title
    valid_details << read_book(book["title"], "#{out_folder}/title.wav", lang)

    puts "Intro"
    # Read book["intro"], #{out_folder}/intro
    valid_details << read_book(book["intro"], "#{out_folder}/intro.wav", lang)

    book["contents"].each_with_index do |content, index|
        puts "Chapter #{index + 1} / #{book["contents"].size}"

        FileUtils.mkdir_p "#{out_folder}/ch_#{index+1}"

        # Read content["title"], #{out_folder}/ch_#{index+1}/title
        valid_details << read_book(content["title"], "#{out_folder}/ch_#{index+1}/title.wav", lang)

        # Read content["intro"], #{out_folder}/ch_#{content["title"]}/intro
        valid_details << read_book(content["intro"], "#{out_folder}/ch_#{index+1}/intro.wav", lang)

        content["contents"].sort_by { |k, v| k.to_i }.each do |k, verses|
            # Read verses, #{out_folder}/ch_#{content["title"]}/verse_#{k}
            puts "Verse #{k}/#{content["contents"].size}"
            valid_details << read_book(verses, "#{out_folder}/ch_#{index+1}/verse_#{k}.wav", lang)
        end
    end

    puts "verify_file: #{verify_file}"
    File.open(verify_file, 'w') { |file| file.write(valid_details.to_json) }
end

skip = true
target = nil # 'kings_3'
data_in_path = 'data/douay_rheims_'
audio_in_path = 'audio_out/'
out_path = 'verify_files/douay_rheims_'
language = 'English'

OptionParser.new do |opt|
  opt.on('--data_inpath [=DATA_INPUT_PATH]') { |o| data_in_path = o }
  opt.on('--audio_inpath [=AUDIO_INPUT_PATH]') { |o| audio_in_path = o }
  opt.on('--outpath [=OUTPUT_PATH]') { |o| out_path = o }
  opt.on('--target [=TARGET]') { |o| target = o }
  opt.on('--language [=LANGUAGE]') { |o| language = o }
end.parse!

FileUtils.mkdir_p File.dirname(out_path)

skip = false if target.nil?

OLD_TESTAMENT_STRUCTURE.each do |book|
    skip = false if book[:name] == target
    next if skip
    read_book_path(book[:name], data_in_path, audio_in_path, out_path, language)
    break
end