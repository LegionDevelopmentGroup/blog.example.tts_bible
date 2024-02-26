
require 'fileutils'
require 'json'
require 'optparse'

require_relative 'util.rb'
require_relative 'book_contents.rb'

def read_book(text, ref, model, vocoder, lang, speaker, ext = '.wav')
    # Call tts function with given text

    if !File.file?(ref)
        run_cmd do
            %x(~/.local/bin/tts --text "#{text.join(' ')}" \
            --model_name "#{model}" \
            --vocoder_name "#{vocoder}" \
            --language_idx "#{lang}" \
            --speaker_idx "#{speaker}" \
            --out_path #{ref})
        end
    end

    target_file = "#{File.join(File.dirname(ref), File.basename(ref, '.wav'))}.mp3"
    
    if !File.file?(target_file)
        run_cmd do
            %x(ffmpeg -i "#{ref}" -codec:a libmp3lame -b:a 320k "#{target_file}")
        end
    end
end

def read_book_path(book_name,
    in_folder_path,
    out_folder_path,
    speaker,
    model,
    vocoder,
    lang)
    #book_name = 'genesis'
    infile = "#{in_folder_path}#{book_name}.json"
    out_folder = "#{out_folder_path}#{book_name}"

    file = File.open(infile)
    book = JSON.load(file)

    # mkdir -p out_folder
    FileUtils.mkdir_p out_folder

    puts "Title"
    # Read book["title"], #{out_folder}/title
    read_book(book["title"], "#{out_folder}/title.wav", model, vocoder, lang, speaker)

    puts "Intro"
    # Read book["intro"], #{out_folder}/intro
    read_book(book["intro"], "#{out_folder}/intro.wav", model, vocoder, lang, speaker)

    book["contents"].each_with_index do |content, index|

        puts "Chapter #{index + 1} / #{book["contents"].size}"

        FileUtils.mkdir_p "#{out_folder}/ch_#{index+1}"

        # Read content["title"], #{out_folder}/ch_#{index+1}/title
        read_book(content["title"], "#{out_folder}/ch_#{index+1}/title.wav", model, vocoder, lang, speaker)

        # Read content["intro"], #{out_folder}/ch_#{content["title"]}/intro
        read_book(content["intro"], "#{out_folder}/ch_#{index+1}/intro.wav", model, vocoder, lang, speaker)

        content["contents"].sort_by { |k, v| k.to_i }.each do |k, verses|
            # Read verses, #{out_folder}/ch_#{content["title"]}/verse_#{k}
            puts "Verse #{k}/#{content["contents"].size}"
            read_book(verses, "#{out_folder}/ch_#{index+1}/verse_#{k}.wav", model, vocoder, lang, speaker)
        end
    end
end

skip = true
target = nil # 'kings_3'
in_path = 'data/douay_rheims_'
out_path = 'audio_out/'

speaker = 'Craig Gutsy'
model = 'tts_models/multilingual/multi-dataset/xtts_v2'
vocoder = 'vocoder_models/universal/libri-tts/wavegrad'
lang = 'en'

OptionParser.new do |opt|
  opt.on('--inpath [=INPUT_PATH]') { |o| in_path = o }
  opt.on('--outpath [=OUTPUT_PATH]') { |o| out_path = o }
  opt.on('--speaker [=SPEAKER]') { |o| speaker = o }
  opt.on('--model [=MODEL]') { |o| model = o }
  opt.on('--vocoder [=VOCODER]') { |o| vocoder = o }
  opt.on('--lang [=LANG]') { |o| lang = o }
  opt.on('--target [=TARGET]') { |o| target = o }
end.parse!

FileUtils.mkdir_p File.dirname(out_path)

skip = false if target.nil?

OLD_TESTAMENT_STRUCTURE.each do |book|
    skip = false if book[:name] == target
    next if skip
    read_book_path(book[:name], in_path, out_path, speaker, model, vocoder, lang)
end