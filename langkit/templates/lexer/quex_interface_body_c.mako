## vim: filetype=makocpp

#include <stdlib.h>

#include "${ada_lib_name.lower()}_quex_interface.h"
#include "${ada_lib_name.lower()}_lexer.h"


struct Lexer {
    QUEX_TYPE_ANALYZER quex_lexer;
    void *buffer;
    quex_Token buffer_tk;

    /* Kind for the previous token (excluding trivia).  */
    uint16_t prev_id;
};


uint16_t
${capi.get_name('lexer_prev_token')}(QUEX_TYPE_ANALYZER *quex_lexer)
{
   return ((struct Lexer *) quex_lexer)->prev_id;
}

static void
init_lexer(Lexer *lexer) {
    QUEX_NAME(token_p_set)(&lexer->quex_lexer, &lexer->buffer_tk);
    memset (&lexer->buffer_tk, 0, sizeof (lexer->buffer_tk));
    lexer->prev_id = 0;
}

Lexer*
${capi.get_name("lexer_from_buffer")}(uint32_t *buffer, size_t length) {
    Lexer* lexer = malloc(sizeof (Lexer));
    /* Quex requires the following buffer layout:

         * characters 0 and 1: null;
         * characters 2 to LENGTH + 1: the actual content to lex;
         * character LENGHT + 2: null.

       And address to pass must be one character past the address of the
       buffer.  Remember that characters are 4 bytes long (this is handled
       thanks to pointer arithmetic).  */
    QUEX_NAME(construct_memory)(&lexer->quex_lexer,
                                buffer + 1, 0,
                                buffer + length + 2,
                                NULL, false);
    init_lexer(lexer);
    return lexer;
}

void
${capi.get_name("free_lexer")}(Lexer* lexer) {
    QUEX_NAME(destruct)(&lexer->quex_lexer);
    free(lexer);
}

int
${capi.get_name("next_token")}(Lexer* lexer, struct token* tok) {
    /* Some lexers need to keep track of the last token: give them this
       information.  */
    lexer->buffer_tk.last_id = lexer->buffer_tk._id;
    QUEX_NAME(receive)(&lexer->quex_lexer);

    tok->id = lexer->buffer_tk._id;
    tok->text = lexer->buffer_tk.text;
    tok->text_length = lexer->buffer_tk.len;
    tok->offset = lexer->buffer_tk.offset;

    /* Update the prev_id field, but only if we just got a token (not a
       trivia).  */
    switch (tok->id) {
        % for token in ctx.lexer.sorted_tokens:
            % if token.is_trivia:
                case ${token.quex_name}:
            % endif
        % endfor
        break;

    default:
        lexer->prev_id = tok->id;
        break;
    }

    return tok->id != 0;
}
