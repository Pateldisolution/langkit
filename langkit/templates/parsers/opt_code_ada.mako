## vim: filetype=makoada

--  Start opt_code

${parser_context.code}

<%
parser_type = parser.parser.get_type()
if parser._booleanize:
   base, alt_true, alt_false = parser._booleanize
%>

if ${parser_context.pos_var_name} = No_Token_Index then
    % if parser._booleanize:
      % if is_bool(base):
         ${parser.res_var} := False;
      % else:
         ${parser.res_var} := ${base.name()}
           (${alt_false.name()}_Alloc.Alloc (Parser.Mem_Pool));
         ${parser.res_var}.Unit := Parser.Unit;
         ${parser.res_var}.Token_Start_Index := ${start_pos};
         ${parser.res_var}.Token_End_Index := No_Token_Index;
      % endif
    % elif parser_type and parser_type.is_list_type:
        ${parser_context.res_var_name} :=
          (${parser_type.storage_type_name()}_Alloc.Alloc (Parser.Mem_Pool));
        ${parser_context.res_var_name}.Unit := Parser.Unit;
        ${parser_context.res_var_name}.Token_Start_Index := ${start_pos} - 1;
        ${parser_context.res_var_name}.Token_End_Index := No_Token_Index;
    % elif parser_type:
        ${parser_context.res_var_name} :=
           ${parser_type.storage_nullexpr()};
    % endif

    % if parser._is_error:
        ## Emit a diagnostic informing the user that the sub parser has not
        ## succeeded.
        Parser.Diagnostics.Append
          ((Get_Token (Parser.TDH.all, ${start_pos}).Sloc_Range,
            To_Unbounded_Wide_Wide_String (To_Text
            ("Missing '${parser.parser.error_repr}'"))));
    % endif

    ${parser_context.pos_var_name} := ${start_pos};

% if parser._booleanize:
else
   % if is_bool (base):
      ${parser.res_var} := True;
   % else:
      ${parser.res_var} := ${base.name()}
        (${alt_true.name()}_Alloc.Alloc (Parser.Mem_Pool));
      ${parser.res_var}.Unit := Parser.Unit;
      ${parser.res_var}.Token_Start_Index := ${start_pos};
      ${parser.res_var}.Token_End_Index := No_Token_Index;
   % endif
% endif

end if;

--  End opt_code
