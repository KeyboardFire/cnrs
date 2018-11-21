#!/usr/bin/ruby

def tr a, c=true
    transposed = ([nil]*a.map(&:size).max).zip(*a)
    c ? transposed.map(&:compact) : transposed.map{|x| x[1..-1]}
end

data = Dir['data/*/*.txt'].map{|x| [x.split(?/)[-1][0..-5], File.read(x)]}.to_h
spec = File.readlines('data/spec').map{|x| x.split(nil, 2)}.to_h.transform_values{|v|
    if v[0] == ?@
        # bold is inverted here because most colored things should also be bolded
        v[1..-1].split.map{|x| [x[0], [x[1], x[2,2], !x[4]]]}.to_h
            .merge({'<' => ['<', '', false]})  # awful hack
    else
        v.split.map{|x| w, d = x.scan(/^\d+|.+/); [w.to_i, d]}
    end
}
layout = tr File.read('data/layout-3col').lines.map(&:split)
colorscheme = '
        .bk, .C                         { color: #555; }
        .re, .DRA                       { color: #a00; }
        .gr, .VEG, .E                   { color: #0a0; }
        .br, .FLE, .LTH, .WOO           { color: #a50; }
        .bl                             { color: #00a; }
        .ma, .S                         { color: #a0a; }
        .cy, .IRN, .MTH, .MET           { color: #0aa; }
        .gy, .N, .SLV, .MIN, .B         { color: #aaa; }
        .no                             { color: #ddd; }
        .or                             { color: #f55; }
        .bg, .M, .GM                    { color: #5f5; }
        .ye, .CPR, .GLD                 { color: #ff5; }
        .bb                             { color: #55f; }
        .bm, .CLO, .PLS, .GEM, .MAT     { color: #f5f; }
        .bc, .GLA                       { color: #5ff; }
        .wh, .L, .WAX, .PAP, .BON, .PLT { color: #fff; }
'
@colors = colorscheme.scan(/\.(\w+)/).map &:first
def html str, clr, bold=false
    str = (str || '').gsub('&', '&amp;').gsub('<', '&lt;')
    classes = []
    classes.push clr if @colors.include? clr
    classes.push 'fb' if bold
    if classes.empty?
        str
    else
        "<b class='#{classes * ' '}'>#{str}</b>"
            .gsub(?', classes.size == 1 ? '' : ?')
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
            b { font-weight: normal; }
            b.fb { font-weight: bold; }

            </style>
        </head>
        <body>
            <pre>
    X

    cols = layout.map do |col|
        col.map do |sec|
            rows = [html("##### #{sec} #####".center(80), 'bb'), ' ' * 80]
            sp = spec[sec]
            data[sec].each_line.with_index do |line, nl|
                sp = spec["#{sec}#{nl}"] || sp
                line.chomp!
                len = 0
                if sp.is_a? Hash
                    rows.push line.gsub(/[#{sp.keys*''}]/) {|x| html(*sp[x]) }
                    len = line.size
                elsif line[0] == ?=
                    rows.push html(line, 'bg')
                    len = line.size
                else
                    rows.push ''
                    eol = line.slice!(80..-1) || ''
                    idx = 0
                    sp.each do |w, d|
                        bold = false
                        clr = d.clone
                        # handle bold
                        if clr && clr[0] == ?&
                            clr.slice! 0
                            bold = true
                        end
                        # handle suppression of space
                        if clr && clr[0] == ?<
                            clr.slice! 0
                            idx -= 1
                        elsif idx > 0
                            rows[-1] += ' '
                            len += 1
                        end
                        # handle special rules
                        clr = case clr
                            when /^\$(\d*)$/ then eol[$1.to_i,2]
                            when ?^ then (line[idx,w] || '').strip
                            else clr
                            end
                        while clr && clr[-3] =~ /[^A-Za-z0-9$^]/
                            clr = eol.include?(clr[-3]) ? clr[-2,2] : clr[0...-3]
                        end
                        rows[-1] += html(line[idx,w], clr, bold)
                        len += (line[idx,w]||'').size
                        idx += w + 1
                    end
                end
                rows[-1] += ' ' * (80 - len)
            end
            rows
        end.reduce{|a,x| a + [' '*80] + x }
    end

    f.puts tr(cols, false).map{|x| x.map{|y| y ? y : ' '*80}.join '  ' }

    f.puts <<~X
            </pre>
        </body>
    </html>
    X
end
