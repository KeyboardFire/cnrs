#!/usr/bin/ruby

def tr a
    ([nil]*a.map(&:size).max).zip(*a).map &:compact
end

data = Dir['data/*/*.txt'].map{|x| [x.split(?/)[-1][0..-5], File.read(x)]}.to_h
spec = File.readlines('data/spec').map{|x| x.split(nil, 2)}.to_h
layout = tr File.read('data/layout-3col').lines.map(&:split)
colorscheme = '
        .bk, .C                         { color: #555; }
        .re, .DRA                       { color: #a00; }
        .gr, .VEG                       { color: #0a0; }
        .br, .FLE, .LTH, .WOO           { color: #a50; }
        .bl                             { color: #00a; }
        .ma                             { color: #a0a; }
        .cy, .IRN, .MTH, .MET           { color: #0aa; }
        .gy, .N, .SLV, .MIN             { color: #aaa; }
        .no                             { color: #ddd; }
        .or                             { color: #f55; }
        .bg                             { color: #5f5; }
        .ye, .CPR, .GLD                 { color: #ff5; }
        .bb                             { color: #55f; }
        .bm, .CLO, .PLS, .GEM, .MAT     { color: #f5f; }
        .bc, .GLA                       { color: #5ff; }
        .wh, .L, .WAX, .PAP, .BON, .PLT { color: #fff; }
'
@colors = colorscheme.scan(/\.(\w+)/).map &:first
def html str, clr
    str = (str || '').gsub('&', '&amp;').gsub('<', '&lt;')
    if @colors.include? clr
        "<span class=#{clr}>#{str}</span>"
    else
        str
    end
end

File.open('cnrs.html', ?w) do |f|
    f.puts <<~X
    <!DOCTYPE html>
    <html lang='en'>
        <head>
            <title>cnrs</title>
            <style>
            body { background-color: #000; color: #ddd; font: 10px monospace; }

            #{colorscheme}

            </style>
        </head>
        <body>
            <pre>
    X

    cols = layout.map do |col|
        col.map do |sec|
            rows = []
            sp = spec[sec].split.map{|x| w, d = x.scan(/^\d+|.+/); [w.to_i, d]}
            data[sec].each_line do |line|
                line.chomp!
                len = 0
                if line[0] == ?=
                    rows.push html(line, 'bg')
                    len = line.size
                else
                    rows.push ''
                    eol = line.slice!(80..-1) || ''
                    idx = 0
                    sp.each do |w, d|
                        clr = case d
                            when /^\$(\d*)$/ then eol[$1.to_i,2]
                            when ?^ then line[idx,w]
                            else d.clone
                            end
                        if clr && clr[0] == ?<
                            clr.slice! 0
                            idx -= 1
                        elsif idx > 0
                            rows[-1] += ' '
                            len += 1
                        end
                        while clr && clr[-3] =~ /[*!]/
                            clr = eol.include?(clr[-3]) ? clr[-2,2] : clr[0...-3]
                        end
                        rows[-1] += html(line[idx,w], clr)
                        len += (line[idx,w]||'').size
                        idx += w + 1
                    end
                end
                rows[-1] += ' ' * (80 - len)
            end
            rows
        end.reduce{|a,x| a + [' '*80] + x }
    end

    f.puts tr(cols).map(&:join)

    f.puts <<~X
            </pre>
        </body>
    </html>
    X
end
