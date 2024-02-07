########
# Takes a single txt of the bible (from gutenberg.org) and parse it into a sturcture json file
# Extracts:
# - Title
# - Introduction
# - Chapters
# - Verse
# - Verse footnotes
########

require 'json'
require 'fileutils'
require 'optparse'

require_relative 'book_contents.rb'

def parse_book(target_file, out_path, out_extension, structure)

    output_file = "#{out_path}#{structure[:name]}.#{out_extension}"
    offset_start = structure[:start]
    offset_end = structure[:end]

    book = {title: [], intro: [], contents: []}

    state = :title # :title, :intro, :chapter, :chapter_intro, :verse, :verse_footnote, :none

    cur_chapter = nil
    cur_verse = nil

    skip_next_whitespace = false

    i = 0
    File.readlines(target_file, chomp: true).each do |line|

        i += 1
        next if i < offset_start
        break if i >= offset_end

        puts "#{i}:#{offset_start}:#{offset_end} line: #{line}"
        # if i > 100
        #     puts "book: #{book.to_json}"
        #     break
        # end
        puts "line: #{line}"
        if line.empty?
            # Empty line
            if skip_next_whitespace
                skip_next_whitespace = false
                next
            end

            if state == :title
                next if book[:title].empty?
                state = :intro
            elsif state == :intro
                next if book[:intro].empty?
                state = :chapter
            elsif state == :chapter
                next if cur_chapter.nil? or book[:contents][cur_chapter][:title].empty?
                state = :chapter_intro
    #       elsif state == :chapter_intro
    #           next if book[:contents][cur_chapter][:intro].empty?
    #           state = :none
    #       elsif state == :verse
    #           next if book[:contents][cur_chapter][:contents].empty? or cur_verse.nil? or book[:contents][cur_chapter][:contents][cur_verse].empty?
    #           state = :none
    #       elsif state == :verse_footnote
    #           next if book[:contents][cur_chapter][:footnotes].empty? or cur_verse.nil?
    #           state = :none
            end
            next
        end

        # Kings 4 has no :intro and thus we need to be able to skip it.
        if state == :intro && line.match(/^(.*) Chapter ([0-9]+)$/)
            state = :chapter
            cur_verse = nil
        end

        puts "State: #{state}"

        if state == :title
            book[:title] << line
        elsif state == :intro
            book[:intro] << line
        else
            puts "State: #{state}"

            # Hack: ECCLESIASTICUS has a "PROLOGUE" following the intro. Adding to the :intro
            if line == 'THE PROLOGUE'
                book[:intro] << line
                state = :intro    
                skip_next_whitespace = true
            end


            # Might need to handle case where Chapter extends multiple lines
            if line.match(/(.*) Chapter ([0-9]+)/)
                puts "chap: #{line}"
                book[:contents] << {title: [line], intro: [], contents: {}, footnotes: {}}
                if cur_chapter.nil?
                    cur_chapter = 0
                else
                    cur_chapter += 1
                end
                state = :chapter
                cur_verse = nil
            elsif (s = line.scan(/^([0-9]+)[:]([0-9]+)[\.\:]?(.+)$/); !s.empty?)
                puts "HERE #{s}"
                puts "cur_chapter: #{cur_chapter}"

                next_verse = s[0][1].strip.to_i
                if !cur_verse.nil? && cur_verse + 1 != next_verse
                    puts "WARNING VERSE SEQUENCE ISSUE! #{cur_verse} - #{next_verse}"
                end

                book[:contents][cur_chapter][:contents][s[0][1].strip.to_i] = [s[0][2].strip]
                cur_verse = next_verse
                state = :verse
            elsif (s = line.scan(/^(.+?)\.\.\./); !s.empty?)
                if book[:contents][cur_chapter][:footnotes][cur_verse].nil?
                    book[:contents][cur_chapter][:footnotes][cur_verse] = []
                end
                book[:contents][cur_chapter][:footnotes][cur_verse] << line
                state = :verse_footnote
            else

                if state == :chapter
                    book[:contents][cur_chapter][:title] << line
                elsif state == :chapter_intro
                    book[:contents][cur_chapter][:intro] << line
                elsif state == :verse
                    book[:contents][cur_chapter][:contents][cur_verse] << line
                elsif state == :verse_footnote
                    book[:contents][cur_chapter][:footnotes][cur_verse] << line
                end
            end
        end
    end

    File.open(output_file, 'w') { |file| file.write(book.to_json) }
end

# ([0-9]+)[:]([0-9]+)\.(.+)$
#   - Chapter : Section
#       - eventually followed by \n ending the section
# 
# ^([\w ]*\w)\.\.\.
#   - Footnotes
# 
# (.*) Chapter ([0-9]+)
#   - Book Chapter #
#   - followed by ^\n
#   - followed by ^(.+)
#   - eventually followed by \n

input_file = 'douay_rheims.txt'
output_path = 'data/douay_rheims_'

OptionParser.new do |opt|
  opt.on('--infile [=INPUT_FILE]') { |o| input_file = o }
  opt.on('--outpath [=OUTPUT_PATH]') { |o| output_path = o }
end.parse!

FileUtils.mkdir_p File.dirname(output_path)

#NEW_TESTAMENT_STRUCTURE
OLD_TESTAMENT_STRUCTURE.each do |structure|
    puts "structure[:name] #{structure[:name]}"
    parse_book(input_file, output_path, "json", structure)
end