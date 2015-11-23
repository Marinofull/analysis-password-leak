IO.write(
  "leak_summary.txt",
  Dir.glob("#{ARGV[0]}/*").map do |f|
    IO.readlines(f).map do |e|
      s = e.strip.split
      puts "Null password in #{f}! Count: #{s[0]}" if s[1].nil?
    
      e.strip
    end
  end.flatten.map do |e|
    s = e.split

    [s[0].to_i, s[1]]
  end.group_by{|e| e[1] }.map do |k, g|
    [
      k,
      g.map{|e| e[0] }.reduce(&:+)
    ]
  end.sort_by{|e| e[1] }.reverse.reduce("") do |str, e|
    str += "#{e[1]}\t#{e[0]}\n"
  end
)
