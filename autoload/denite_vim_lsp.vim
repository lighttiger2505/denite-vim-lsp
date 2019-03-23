let s:last_req_id = 0

" function! s:symbols_to_list(result) abort
"     if !has_key(a:result['response'], 'result')
"         return []
"     endif
"
"     let l:list = []
"
"     let l:locations = type(a:result['response']['result']) == type({}) ? [a:result['response']['result']] : a:result['response']['result']
"
"     if !empty(l:locations) " some servers also return null so check to make sure it isn't empty
"         for l:symbol in a:result['response']['result']
"             let l:location = l:symbol['location']
"             if s:is_file_uri(l:location['uri'])
"                 let l:path = lsp#utils#uri_to_path(l:location['uri'])
"                 let l:bufnr = bufnr(l:path)
"                 let l:line = l:location['range']['start']['line'] + 1
"                 let l:col = l:location['range']['start']['character'] + 1
"                 call add(l:list, {
"                    \ 'filename': l:path,
"                    \ 'lnum': l:line,
"                    \ 'col': l:col,
"                    \ 'text': s:get_symbol_text_from_kind(l:symbol['kind']) . ' : ' . l:symbol['name'],
"                    \ })
"             endif
"         endfor
"     endif
"
"     return l:list
" endfunction

function! s:not_supported(what) abort
    return lsp#utils#error(a:what.' not supported for '.&filetype)
endfunction

function! s:handle_symbol(server, last_req_id, type, data) abort
    " if a:last_req_id != s:last_req_id
    "     return
    " endif

    if lsp#client#is_error(a:data['response'])
        call lsp#utils#error('Failed to retrieve '. a:type . ' for ' . a:server . ': ' . lsp#client#error_message(a:data['response']))
        return
    endif

    let l:result = a:data['response']['result']
    let g:denite#source#vim_lsp#_request_completed = v:true
    let g:denite#source#vim_lsp#_results = l:result
endfunction

function! denite_vim_lsp#document_symbol() abort
    let l:servers = filter(lsp#get_whitelisted_servers(), 'lsp#capabilities#has_document_symbol_provider(v:val)')
    let s:last_req_id = s:last_req_id + 1

    if len(l:servers) == 0
        call s:not_supported('Retrieving symbols')
        return
    endif

    for l:server in l:servers
        call lsp#send_request(l:server, {
            \ 'method': 'textDocument/documentSymbol',
            \ 'params': {
            \   'textDocument': lsp#get_text_document_identifier(),
            \ },
            \ 'sync': 1,
            \ 'on_notification': function('s:handle_symbol', [l:server, s:last_req_id, 'documentSymbol']),
            \ })
    endfor
endfunction

function! denite_vim_lsp#workspace_symbol() abort
    let l:servers = filter(lsp#get_whitelisted_servers(), 'lsp#capabilities#has_workspace_symbol_provider(v:val)')
    let s:last_req_id = s:last_req_id + 1

    if len(l:servers) == 0
        call s:not_supported('Retrieving workspace symbols')
        return
    endif

    for l:server in l:servers
        call lsp#send_request(l:server, {
            \ 'method': 'workspace/symbol',
            \ 'params': {
            \   'query': '',
            \ },
            \ 'sync': 1,
            \ 'on_notification': function('s:handle_symbol', [l:server, s:last_req_id, 'workspaceSymbol']),
            \ })
    endfor
endfunction
