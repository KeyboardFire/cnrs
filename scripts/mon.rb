#!/usr/bin/ruby

NHPATH = '/home/llama/code/misc/nethack-3.6.1/'
def get x
    File.read(NHPATH + x)
end

@seduction = 'A(ATTK(AT_BITE, AD_SSEX, 0, 0), ATTK(AT_CLAW, AD_PHYS, 1, 3), ATTK(AT_CLAW, AD_PHYS, 1, 3))'

def argify s
    depth = 1
    idx = s.index('(')
    return [s] unless idx
    idx += 1
    args = ['']
    while depth > 0 || args[0] == ''
        args[-1] += s[idx] if s[idx] != ',' || depth > 1
        case s[idx += 1]
        when '(' then depth += 1
        when ')' then depth -= 1
        when ',' then args.push '' if depth == 1
        end
    end
    args.map &:strip
end

def flagify s, fn=->x{x}
    s[0] == '0' ? [] : s.split('|').map{|x| fn[x.strip[3..-1].to_sym]}
end
resfunc = ->x{{
    FIRE: ?F, COLD: ?C, POISON: ?P, SLEEP: ?L, SHOCK: ?H, DISINT: ?D, ACID: ?A,
    STONE: ?T, ELEC: ?E
}[x]||(puts x)}
eatfunc = ->x{{POIS: ?p, ACID: ?a}[x]}

syms = get('include/monsym.h').scan(/#define DEF_([^ ]*) *'\\?(.)'/).to_h
colors = {
    CLR_BLACK:          'bk',
    CLR_RED:            're',
    CLR_GREEN:          'gr',
    CLR_BROWN:          'br',
    CLR_BLUE:           'bl',
    CLR_MAGENTA:        'ma',
    CLR_CYAN:           'cy',
    CLR_GRAY:           'gy',
    CLR_ORANGE:         'or',
    CLR_BRIGHT_GREEN:   'bg',
    CLR_YELLOW:         'ye',
    CLR_BRIGHT_BLUE:    'bb',
    CLR_BRIGHT_MAGENTA: 'bm',
    CLR_BRIGHT_CYAN:    'bc',
    CLR_WHITE:          'wh',
    DRAGON_SILVER:      'bc',
    HI_DOMESTIC:        'wh',
    HI_GOLD:            'ye',
    HI_LEATHER:         'br',
    HI_LORD:            'ma',
    HI_METAL:           'cy',
    HI_PAPER:           'wh',
    HI_WOOD:            'br',
    HI_ZAP:             'bb',
}

def a2s a
    return if a == 'NO_ATTK'
    return argify(@seduction).map{|x| a2s x}*?, if a == 'SEDUCTION_ATTACKS_YES'
    at, ad, n, m = argify(a.downcase)
    "#{at[3..-1]} #{n}d#{m} #{ad[3..-1]}".sub(' phys', '')
        .sub(/ 0d(0|70)/, '').sub(' 1d', ' d')
        .sub(/(claw|bite|kick|butt|tuch|stng|tent) /, '')
        .sub(/magc (.*(spel|magm))/, '\1')
end

def collapse a
    a.chunk{|x| x}.map{|_, x| "#{x.size}*#{x[0]}".sub('1*', '')}
end

def compress s, d
    return '*' if s == d
    c = d.delete s
    c.size+1 < s.size ? "-#{c}" : s
end

data = get 'src/monst.c'
data = data[data.index('struct permonst')..data.index('terminator')]
data.gsub! /#if( 0|def CHARON).*?#endif/m, ''
data = data.split(/(?=MON\()/)[1..-1]
data.map! do |x|
    name, sym, lvl, cflags, atk, siz, res, conf, f1, f2, f3, color =
        argify x.gsub(/\/\*.*?\*\//, '')
    [
        name[1...-1],
        syms[sym[2..-1]],
        ->x{x>=50?x/2-3:x}[argify(lvl)[0].to_i].to_s,
        argify(lvl)[1],
        argify(siz)[1],
        compress(flagify(res, resfunc)*'', 'FCLDEPAT'),
        compress(flagify(conf, resfunc)*'', 'FCLDEPT'),
        flagify(f1, eatfunc).compact.join.sub('ap','*'),
        collapse(argify(atk).map{|a| a2s a}.compact) * ?,,
        colors[color.to_sym] || color,
    ]
end

# data.each{|x| puts x[8].split(?,)}

fmt = data.map{|x| x.map &:size }.transpose.map(&:max).zip('-    -- - '.chars)
    .map{|x,a| "%#{a}#{x}s" } * ' '
data.each{|x| printf fmt, *x; puts}
