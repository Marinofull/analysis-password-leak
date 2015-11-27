#The MIT License (MIT)
#
#Copyright (c) 2015 Marino Souza, Nilton Vasques and Romário Rios

def gnuplot(commands)
  IO.popen("gnuplot", "w") { |io| io.puts commands }
end

def plot_hist(dat, output, xlabel, ylabel, title = "logscale histogram")
  commands = %Q(
    set title '#{title}'
    set key right bottom
    set xlabel "#{xlabel}"
    set ylabel "#{ylabel}"
    
    set term png size 1000,500
    set output "#{output}"
    set logscale y
    set xtics 100
    plot "#{dat}" using 2: xtic(1) with histogram notitle
  )
  gnuplot(commands)
end

