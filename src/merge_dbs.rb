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

  def database
    @database
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

@last_day_of_month = [0,31,29,31,30,31,30,31,31,30,31,30,31]

def is_date_eight(dd, mm, yyyy)
  mm.between?(1, 12) && dd.between?(1,@last_day_of_month[mm]) and yyyy.between?(1900, Time.now.year)
end
def is_date_six(dd, mm, yy)
  mm.between?(1, 12) && dd.between?(1,@last_day_of_month[mm]) and yy.between?(00, 99)
end

def date_pattern(passwords)
  eight_digits = 0.00
  ddmmyyyy = 0.00
  mmddyyyy = 0.00
  yyyymmdd = 0.00

  six_digits = 0.00
  ddmmyy = 0.00
  mmddyy = 0.00
  yymmdd = 0.00

  passwords.group_all.each do |e|
    # 8 digits patterns
    if e[:pass] =~ /^[0-9]{8}$/
      eight_digits += 1
      dd =  e[:pass][0..1].to_i
      mm = e[:pass][2..3].to_i
      yyyy = e[:pass][4..7].to_i
      #  DDMMYYYY
      ddmmyyyy += 1 if is_date_eight(dd, mm, yyyy)
      mm =  e[:pass][0..1].to_i
      dd = e[:pass][2..3].to_i
      yyyy = e[:pass][4..7].to_i
      #  MMDDYYYY
      mmddyyyy += 1 if is_date_eight(dd, mm, yyyy)
      yyyy = e[:pass][0..3].to_i
      mm =  e[:pass][4..5].to_i
      dd = e[:pass][6..7].to_i
      #  YYYYMMDD
      yyyymmdd += 1 if is_date_eight(dd, mm, yyyy)
    # 6 digits patterns
    else
      if e[:pass] =~ /^[0-9]{6}$/
        six_digits += 1
        dd =  e[:pass][0..1].to_i
        mm = e[:pass][2..3].to_i
        yy = e[:pass][4..5].to_i
        #  DDMMYY
        ddmmyy += 1 if is_date_six(dd, mm, yy)
        mm =  e[:pass][0..1].to_i
        dd = e[:pass][2..3].to_i
        yy = e[:pass][4..5].to_i
        #  MMDDYY
        mmddyy += 1 if is_date_six(dd, mm, yy)
        yy = e[:pass][0..1].to_i
        mm =  e[:pass][2..3].to_i
        dd = e[:pass][4..5].to_i
        #  YYMMDD
        yymmdd += 1 if is_date_six(dd, mm, yy)
      end
    end
  end
  eight_digits_percent = ( eight_digits/passwords.total ) * 100.00
  eight_digits_date = ddmmyyyy + mmddyyyy + yyyymmdd
  eight_digits_date_percent = (eight_digits_date)/passwords.total * 100

  six_digits_percent = ( six_digits/passwords.total ) * 100.00
  six_digits_date = ddmmyy + mmddyy + yymmdd
  six_digits_date_percent = (six_digits_date)/passwords.total * 100
<<EOF
  -------------------------------------------------------------------------------------------------------------
  Consecutive Exactly eight digits: #{eight_digits} - #{eight_digits_percent} %
  Are eight digits date: #{eight_digits_date} - #{eight_digits_date_percent} %

  Amount Date       total percent       date8 percent       digits8 percent
  DDMMYYYY #{ddmmyyyy} \t #{( ddmmyyyy/passwords.total ) * 100.00} % \t #{ ( ddmmyyyy/eight_digits_date) * 100.00} % \t #{ ( ddmmyyyy/eight_digits) * 100.00} %
  MMDDYYYY #{mmddyyyy} \t #{( mmddyyyy/passwords.total ) * 100.00} % \t #{ ( mmddyyyy/eight_digits_date) * 100.00} % \t #{ ( mmddyyyy/eight_digits) * 100.00} %
  YYYYMMDD #{yyyymmdd} \t #{( yyyymmdd/passwords.total ) * 100.00} % \t #{ ( yyyymmdd/eight_digits_date) * 100.00} % \t #{ ( yyyymmdd/eight_digits) * 100.00} %

  -------------------------------------------------------------------------------------------------------------

  -------------------------------------------------------------------------------------------------------------
   Consecutive Exactly six digits: #{six_digits} - #{six_digits_percent} %
  Are six digits date: #{six_digits_date} - #{six_digits_date_percent} %

  Amount Date       total percent       date6 percent       digits6 percent
  DDMMYY #{ddmmyy} \t \t #{( ddmmyy/passwords.total ) * 100.00} % \t #{ ( ddmmyy/six_digits_date ) * 100.00} % \t #{ ( ddmmyy/six_digits) * 100.00} %

  MMDDYY #{mmddyy} \t \t #{( mmddyy/passwords.total ) * 100.00} % \t #{ ( mmddyy/six_digits_date ) * 100.00} % \t #{ ( mmddyy/six_digits) * 100.00} %
  YYMMDD #{yymmdd} \t \t #{( yymmdd/passwords.total ) * 100.00} % \t #{ ( yymmdd/six_digits_date ) * 100.00} % \t #{ ( yymmdd/six_digits) * 100.00} %
 -------------------------------------------------------------------------------------------------------------
EOF
end

passwords = PasswordDB.new(ARGV)

leak_summary =
  "Files analysed:\n" +
  passwords.files.reduce("") do |str, f|
    str += "\t#{f}\n"
  end +
  "Total: #{passwords.total}\n" +
  date_pattern(passwords) +
  passwords.group_all.sort_by{|e| e[:count] }.reverse.reduce("") do |str, e|
    str +=
      "#{e[:count]}\t"\
      "#{'%.3f' % (e[:count].to_f * 100 / passwords.total)}%\t"\
      "#{e[:pass]}\n"
  end


IO.write("leak_summary.txt", leak_summary)
