" Vim plugin for showing matching html tags.
" Maintainer:  Greg Sexton <gregsexton@gmail.com>
" Credits: Bram Moolenar and the 'matchparen' plugin from which this draws heavily.

if exists("b:did_ftplugin")
    finish
endif

let s:selfclosing = [
    \ 'meta',
    \ 'link',
    \ 'img',
    \ 'input',
    \ 'area',
    \ 'base',
    \ 'br',
    \ 'hr',
    \ 'param',
    \ 'col',
    \ ]

augroup matchhtmlparen
  autocmd! CursorMoved,CursorMovedI,WinEnter <buffer> call s:Highlight_Matching_Pair()
augroup END

fu! s:Highlight_Matching_Pair()
    " Remove any previous match.
    if exists('w:tag_hl_on') && w:tag_hl_on
        2match none
        let w:tag_hl_on = 0
    endif

    " Avoid that we remove the popup menu.
    " Return when there are no colors (looks like the cursor jumps).
    if pumvisible() || (&t_Co < 8 && !has("gui_running"))
        return
    endif

    " When not in a string or comment ignore matches inside them.
    let hlgroup = synIDattr(synID(line("."), col("."), 0), "name")
    if hlgroup =~? 'htmlString\|htmlComment\|htmlCommentPart'
        retu
    endif

    "get html tag under cursor
    let tagname = s:GetCurrentCursorTag()
    if tagname == ""
        return
    endif

    if tagname[0] == '/'
        let position = s:SearchForMatchingTag(tagname[1:], 0)
    else
        let position = s:SearchForMatchingTag(tagname, 1)
    endif
    call s:HighlightTagAtPosition(position)
endfu

fu! s:GetCurrentCursorTag()
    "returns the tag under the cursor, includes the '/' if on a closing tag.

    let c_col  = col('.')
    let matched = matchstr(getline('.'), '\(<[^<>]*\%'.c_col.'c.\{-}>\)\|\(\%'.c_col.'c<.\{-}>\)')
    if matched == ""
        return matched
    endif

    let tagname = matchstr(matched, '<\zs.\{-}\ze[ >]')
    return tagname
endfu

fu! s:SearchForMatchingTag(tagname, forwards)
    "returns the position of a matching tag or [[0 0], 1] / [[0 0], 0]

    let starttag = '<'.a:tagname.'.\{-}>'
    let midtag = ''
    let endtag = '</'.a:tagname.'.\{-}>'.(a:forwards?'':'\zs')
    let flags = 'nW'.(a:forwards?'':'b')
    let skip = 0

    " Limit the search to lines visible in the window.
    "let stopline = a:forwards ? line('w$') : line('w0')
    let stopline = 0
    let timeout = 300

    " Is it a self closing element or a unclosed tag?
    let doerror = index(s:selfclosing, a:tagname) >= 0 ? 0 : 1

    return [searchpairpos(starttag, midtag, endtag, flags, skip, stopline, timeout), doerror]
endfu

fu! s:HighlightTagAtPosition(position)
    if a:position[0] == [0, 0]
        if a:position[1]
            cal s:Hightlight(a:position[0], 'Error')
        endif

        return
    endif

    cal s:Hightlight(a:position[0], 'MatchParen')
endfu

fu! s:Hightlight(position, hlgroup)
    let [m_lnum, m_col] = a:position

    exe '2match' a:hlgroup '/\(\%' . m_lnum . 'l\%' . m_col .  'c<\zs.\{-}\ze[ >]\)\|'
        \ .'\(\%' . line('.') . 'l\%' . col('.') .  'c<\zs.\{-}\ze[ >]\)\|'
        \ .'\(\%' . line('.') . 'l<\zs[^<> ]*\%' . col('.') . 'c.\{-}\ze[ >]\)\|'
        \ .'\(\%' . line('.') . 'l<\zs[^<>]\{-}\ze\s[^<>]*\%' . col('.') . 'c.\{-}>\)/'
    let w:tag_hl_on = 1
endf

"vim:et:ts=4:sw=4:sts=4
