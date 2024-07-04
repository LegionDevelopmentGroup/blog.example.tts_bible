
require 'fileutils'
require 'json'
require 'optparse'

require "google/cloud/text_to_speech"
require 'net/http'
require 'uri'

require_relative 'util.rb'
require_relative 'book_contents.rb'
require_relative 'book_reader.rb'

# limit 1 mill free
class GoogleCloudReader
    def initialize
        @client = Google::Cloud::TextToSpeech.text_to_speech do |config|
        end
    end

    def read_book(text, ref, model, vocoder, lang, speaker, ext = '.wav')
        # Call tts function with given text

        target_file = "#{File.join(File.dirname(ref), File.basename(ref, '.wav'))}.mp3"

        if !File.file?(target_file)
            
            # Specify the voice and audio configuration
            voice = {
              language_code: "en-US",
              name: "en-US-Wavenet-D", # You can choose different voices
            }

            audio_config = {
              audio_encoding: Google::Cloud::TextToSpeech::V1::AudioEncoding::MP3,
            }

            # Generate speech using Text-to-Speech API
            response = @client.synthesize_speech input: {text: text.join(' ')}, voice: voice, audio_config: audio_config

            # Save the MP3 audio data to a local file
            File.open(target_file, "wb") do |file|
              file.write(response.audio_content)
            end
        end
    end
end

skip = true
target = nil # 'kings_3'
in_path = 'data/douay_rheims_'
out_path = 'audio_out/'

max_token_limit = 750000
tokens_already_used = 0

OptionParser.new do |opt|
  opt.on('--inpath [=INPUT_PATH]') { |o| in_path = o }
  opt.on('--outpath [=OUTPUT_PATH]') { |o| out_path = o }
  opt.on('--target [=TARGET]') { |o| target = o }
  opt.on('--used_tokens [=USED_TOKENS]', { |o| tokens_already_used = o })
end.parse!

FileUtils.mkdir_p File.dirname(out_path)

skip = false if target.nil?

book_reader = BookReader.new(GoogleCloudReader.new, max_token_limit, tokens_already_used)

BIBLE_STRUCTURE.each do |book|
    skip = false if book[:name] == target
    next if skip
    puts "Book: #{book[:name]}"
    book_reader.read_book_path(book[:name], in_path, out_path, '', '', '', '')
end