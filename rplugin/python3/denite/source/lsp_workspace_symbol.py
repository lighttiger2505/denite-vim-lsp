import logging
import os
from urllib.parse import urlparse

from .base import Base

logger = logging.getLogger()
logger.setLevel(logging.INFO)

handler = logging.FileHandler('denitevimlsp.log')
fmt = logging.Formatter('%(asctime)s [%(levelname)s]: %(message)s')
handler.setFormatter(fmt)
handler.setLevel(logging.INFO)
logger.addHandler(handler)

LSP_SYMBOL_KINDS = [
    'File',
    'Module',
    'Namespace',
    'Package',
    'Class',
    'Method',
    'Property',
    'Field',
    'Constructor',
    'Enum',
    'Interface',
    'Function',
    'Variable',
    'Constant',
    'String',
    'Number',
    'Boolean',
    'Array',
    'Object',
    'Key',
    'Null',
    'EnumMember',
    'Struct',
    'Event',
    'Operator',
    'TypeParameter',
]


class Source(Base):
    def __init__(self, vim):
        super().__init__(vim)
        self.name = 'lsp_workspace_symbol'
        self.kind = 'file'

        self.vim.vars['denite#source#vim_lsp#_results'] = []
        self.vim.vars['denite#source#vim_lsp#_request_completed'] = False

    def gather_candidates(self, context):
        if context['is_async']:
            if self.vim.vars['denite#source#vim_lsp#_request_completed']:
                context['is_async'] = False
                return make_candidates(
                    self.vim.vars['denite#source#vim_lsp#_results'])
            return []

        self.vim.vars['denite#source#vim_lsp#_request_completed'] = False
        context['is_async'] = True
        self.vim.call('denite_vim_lsp#workspace_symbol')
        return []


def make_candidates(symbols):
    if not symbols:
        logger.info('symbol nothing')
        return []
    if not isinstance(symbols, list):
        logger.info('symbol is not list')
        return []
    candidates = [_parse_candidate(symbol) for symbol in symbols]
    return candidates


def _parse_candidate(symbol):
    candidate = {}
    loc = symbol['location']
    p = urlparse(loc['uri'])
    fp = os.path.abspath(os.path.join(p.netloc, p.path))

    candidate['word'] = symbol['name']
    candidate['abbr'] = '{} [{}] {}'.format(
        symbol['name'],
        LSP_SYMBOL_KINDS[symbol['kind'] - 1],
        fp,
    )

    candidate['action__path'] = fp
    candidate['action__line'] = loc['range']['start']['line'] + 1
    candidate['action__col'] = loc['range']['start']['character'] + 1
    return candidate
