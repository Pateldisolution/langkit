"""
Test that garbage tokens left after the main parsing rule completes does not
crash. It used to!
"""

from __future__ import absolute_import, division, print_function

from langkit.dsl import ASTNode
from langkit.parsers import Grammar

from lexer_example import Token
from utils import build_and_run


class FooNode(ASTNode):
    pass


class Literal(FooNode):
    token_node = True


foo_grammar = Grammar('main_rule')
foo_grammar.add_rules(
    main_rule=Literal(Token.Number),
)
build_and_run(foo_grammar, 'main.py')
print('Done')
