class PasswordDB
  def initialize(entry_list)
    @database =
      entry_list.map do |arg|
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
          {file: f, line: e_fixed.strip}
        end
      end.flatten.map do |e|
        s = e[:line].split
        puts "Null password in #{e[:file]}! Count: #{s[0]}" if s[1].nil?
        
        {file: e[:file], count: s[0].to_i, pass: s[1]}
      end
  end
  
  def total
    @total = @database.reduce(0) do |partial, e|
      partial += e[:count]
    end if @total.nil?
    
    @total
  end
  
  def files
    @files = @database.map{|e| e[:file] }.uniq if @files.nil?
    
    @files
  end
  
  def group_all
    @database.group_by{|e| e[:pass] }.map do |k, g|
      {
        pass: k,
        count: g.map{|e| e[:count] }.reduce(&:+),
        files: g.map{|e| e[:file] }
      }
    end
  end
end

passwords = PasswordDB.new(ARGV)

leak_summary =
  "Files analysed:\n" +
  passwords.files.reduce("") do |str, f|
    str += "\t#{f}\n"
  end +
  "Total: #{passwords.total}\n" +
  passwords.group_all.sort_by{|e| e[:count] }.reverse.reduce("") do |str, e|
    str +=
      "#{e[:count]}\t"\
      "#{'%.3f' % (e[:count].to_f * 100 / passwords.total)}%\t"\
      "#{e[:pass]}\n"
  end

IO.write("leak_summary.txt", leak_summary)
