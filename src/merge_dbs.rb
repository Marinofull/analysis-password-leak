passwords =
  ARGV.map do |arg|
    if File.file?(arg)
      arg
    elsif File.directory?(arg)
      Dir.glob("#{arg}/*")
    else
      puts "#{arg} not file or directory"
      []
    end
  end.flatten.map do |f|
    IO.readlines(f).map do |e|
      e_fixed = e.encode('UTF-8', invalid: :replace, undef: :replace)
      s = e_fixed.strip.split
      puts "Null password in #{f}! Count: #{s[0]}" if s[1].nil?
    
      e_fixed.strip
    end
  end.flatten.map do |e|
    s = e.split

    [s[0].to_i, s[1]]
  end.group_by{|e| e[1] }.map do |k, g|
    [
      k,
      g.map{|e| e[0] }.reduce(&:+)
    ]
  end

total = passwords.reduce(0){|partial, pass| partial += pass[1] }

IO.write(
  "leak_summary.txt",
  passwords.sort_by{|e| e[1] }.reverse.reduce("") do |str, e|
    str += "#{e[1]}\t#{'%.3f' % (e[1].to_f * 100 / total)}%\t#{e[0]}\n"
  end
)
