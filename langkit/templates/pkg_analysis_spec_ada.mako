## vim: filetype=makoada

<%namespace name="array_types"   file="array_types_ada.mako" />
<%namespace name="astnode_types" file="astnode_types_ada.mako" />
<%namespace name="entities"      file="entities_ada.mako" />
<%namespace name="exts"          file="extensions.mako" />

<% no_builtins = lambda ts: filter(lambda t: not t.is_builtin(), ts) %>

with Ada.Containers;
with Ada.Unchecked_Deallocation;

with System;

with Langkit_Support.Bump_Ptr;    use Langkit_Support.Bump_Ptr;
with Langkit_Support.Diagnostics; use Langkit_Support.Diagnostics;
with Langkit_Support.Slocs;       use Langkit_Support.Slocs;
with Langkit_Support.Symbols;     use Langkit_Support.Symbols;
with Langkit_Support.Text;        use Langkit_Support.Text;

--  TODO??? Turn the following into a PRIVATE WITH
with ${ada_lib_name}.Implementation;
with ${ada_lib_name}.Common;     use ${ada_lib_name}.Common;

with ${ada_lib_name}.Lexer; use ${ada_lib_name}.Lexer;
use ${ada_lib_name}.Lexer.Token_Data_Handlers;

${exts.with_clauses(with_clauses)}

--  This package provides types and primitives to analyze source files as
--  analysis units.
--
--  This is the entry point to parse and process a unit: first create an
--  analysis context with Create, then get analysis units out of it using
--  Get_From_File and/or Get_From_Buffer.

package ${ada_lib_name}.Analysis is

   type Analysis_Context is private;
   ${ada_doc('langkit.analysis_context_type', 3)}

   type Analysis_Unit is private;
   ${ada_doc('langkit.analysis_unit_type', 3)}

   No_Analysis_Unit : constant Analysis_Unit;
   --  Special value to mean the absence of analysis unit. No analysis units
   --  can be passed this value.

   No_Analysis_Context : constant Analysis_Context;
   --  Special value to mean the absence of analysis unit. No analysis units
   --  can be passed this value.

   ---------------
   -- AST nodes --
   ---------------

   % for e in ctx.entity_types:
      % if e.is_root_type:
         type ${e.api_name} is tagged private;
      % else:
         type ${e.api_name} is new ${e.base.api_name} with private;
      % endif
   % endfor

   % for e in ctx.entity_types:
      No_${e.api_name} : constant ${e.api_name};
   % endfor

   ${entities.decls1()}

   --------------------
   -- Unit providers --
   --------------------

   type Unit_Provider_Interface is limited interface;
   type Unit_Provider_Access is
      access all Unit_Provider_Interface'Class;
   type Unit_Provider_Access_Cst is
      access constant Unit_Provider_Interface'Class;
   ${ada_doc('langkit.unit_provider_type', 3)}

   function Get_Unit_Filename
     (Provider : Unit_Provider_Interface;
      Name     : Text_Type;
      Kind     : Unit_Kind) return String is abstract;
   ${ada_doc('langkit.unit_provider_get_unit_filename', 3)}

   function Get_Unit
     (Provider    : Unit_Provider_Interface;
      Context     : Analysis_Context;
      Name        : Text_Type;
      Kind        : Unit_Kind;
      Charset     : String := "";
      Reparse     : Boolean := False) return Analysis_Unit is abstract;
   ${ada_doc('langkit.unit_provider_get_unit_from_name', 3)}

   procedure Destroy is new Ada.Unchecked_Deallocation
     (Unit_Provider_Interface'Class, Unit_Provider_Access);

   ---------------------------------
   -- Analysis context primitives --
   ---------------------------------

   function Create
     (Charset     : String := Default_Charset;
      With_Trivia : Boolean := True
      % if ctx.default_unit_provider:
         ; Unit_Provider : Unit_Provider_Access_Cst := null
      % endif
     ) return Analysis_Context;
   ${ada_doc('langkit.create_context', 3)}

   function Has_With_Trivia (Context : Analysis_Context) return Boolean;
   --  Return whether Context keeps trivia when parsing units

   procedure Discard_Errors_In_Populate_Lexical_Env
     (Context : Analysis_Context; Discard : Boolean);
   ${ada_doc('langkit.context_discard_errors_in_populate_lexical_env', 3)}

   procedure Set_Logic_Resolution_Timeout
     (Context : Analysis_Context; Timeout : Natural);
   ${ada_doc('langkit.context_set_logic_resolution_timeout', 3)}

   function Has_Rewriting_Handle (Context : Analysis_Context) return Boolean;
   --  Return whether Context has a rewriting handler (see
   --  ${ada_lib_name}.Rewriting), i.e. whether it is in the process of
   --  rewriting. If true, this means that the set of currently loaded analysis
   --  units is frozen until the rewriting process is done.

   function Has_Unit
     (Context       : Analysis_Context;
      Unit_Filename : String) return Boolean;
   --  Returns whether Context contains a unit correponding to Unit_Filename

   function Get_From_File
     (Context  : Analysis_Context;
      Filename : String;
      Charset  : String := "";
      Reparse  : Boolean := False;
      Rule     : Grammar_Rule := Default_Grammar_Rule) return Analysis_Unit
      with Pre => not Reparse or else not Has_Rewriting_Handle (Context);
   ${ada_doc('langkit.get_unit_from_file', 3)}

   function Get_From_Buffer
     (Context  : Analysis_Context;
      Filename : String;
      Charset  : String := "";
      Buffer   : String;
      Rule     : Grammar_Rule := Default_Grammar_Rule) return Analysis_Unit
      with Pre => not Has_Rewriting_Handle (Context);
   ${ada_doc('langkit.get_unit_from_buffer', 3)}

   function Get_With_Error
     (Context  : Analysis_Context;
      Filename : String;
      Error    : String;
      Charset  : String := "";
      Rule     : Grammar_Rule := Default_Grammar_Rule) return Analysis_Unit;
   --  If a Unit for Filename already exists, return it unchanged. Otherwise,
   --  create an empty analysis unit for Filename with a diagnostic that
   --  contains the Error message.

   % if ctx.default_unit_provider:

   function Get_From_Provider
     (Context : Analysis_Context;
      Name    : Text_Type;
      Kind    : Unit_Kind;
      Charset : String := "";
      Reparse : Boolean := False) return Analysis_Unit
      with Pre => not Reparse or else not Has_Rewriting_Handle (Context);
   ${ada_doc('langkit.get_unit_from_provider', 3)}

   function Unit_Provider
     (Context : Analysis_Context) return Unit_Provider_Access_Cst;
   --  Object to translate unit names to file names
   % endif

   procedure Remove (Context : Analysis_Context; Filename : String)
      with Pre => not Has_Rewriting_Handle (Context);
   ${ada_doc('langkit.remove_unit', 3)}

   procedure Inc_Ref (Context : Analysis_Context);
   ${ada_doc('langkit.context_incref', 3)}

   procedure Dec_Ref (Context : in out Analysis_Context);
   ${ada_doc('langkit.context_decref', 3)}

   procedure Destroy (Context : in out Analysis_Context)
      with Pre => not Has_Rewriting_Handle (Context);
   ${ada_doc('langkit.destroy_context', 3)}

   ------------------------------
   -- Analysis unit primitives --
   ------------------------------

   function Context (Unit : Analysis_Unit) return Analysis_Context;
   --  Return the analysis context that owns Unit

   procedure Inc_Ref (Unit : Analysis_Unit);
   ${ada_doc('langkit.unit_incref', 3)}

   procedure Dec_Ref (Unit : in out Analysis_Unit);
   ${ada_doc('langkit.unit_decref', 3)}

   function Get_Context (Unit : Analysis_Unit) return Analysis_Context;
   ${ada_doc('langkit.unit_context', 3)}

   procedure Reparse (Unit : Analysis_Unit; Charset : String := "");
   ${ada_doc('langkit.unit_reparse_file', 3)}

   procedure Reparse
     (Unit    : Analysis_Unit;
      Charset : String := "";
      Buffer  : String);
   ${ada_doc('langkit.unit_reparse_buffer', 3)}

   procedure Populate_Lexical_Env (Unit : Analysis_Unit);
   ${ada_doc('langkit.unit_populate_lexical_env', 3)}

   function Get_Filename (Unit : Analysis_Unit) return String;
   ${ada_doc('langkit.unit_filename', 3)}

   function Get_Charset (Unit : Analysis_Unit) return String;
   --  Return the charset that was used to parse Unit

   function Has_Diagnostics (Unit : Analysis_Unit) return Boolean;
   ${ada_doc('langkit.unit_has_diagnostics', 3)}

   function Diagnostics (Unit : Analysis_Unit) return Diagnostics_Array;
   ${ada_doc('langkit.unit_diagnostics', 3)}

   function Format_GNU_Diagnostic
     (Unit : Analysis_Unit; D : Diagnostic) return String;
   --  Format a diagnostic in a GNU fashion. See
   --  <https://www.gnu.org/prep/standards/html_node/Errors.html>.

   pragma Warnings (Off, "defined after private extension");
   function Root (Unit : Analysis_Unit) return ${root_entity.api_name};
   ${ada_doc('langkit.unit_root', 3)}
   pragma Warnings (On, "defined after private extension");

   function First_Token (Unit : Analysis_Unit) return Token_Type;
   ${ada_doc('langkit.unit_first_token', 3)}

   function Last_Token (Unit : Analysis_Unit) return Token_Type;
   ${ada_doc('langkit.unit_last_token', 3)}

   function Token_Count (Unit : Analysis_Unit) return Natural;
   ${ada_doc('langkit.unit_token_count', 3)}

   function Trivia_Count (Unit : Analysis_Unit) return Natural;
   ${ada_doc('langkit.unit_trivia_count', 3)}

   function Text (Unit : Analysis_Unit) return Text_Type;
   ${ada_doc('langkit.unit_text', 3)}

   function Lookup_Token
     (Unit : Analysis_Unit; Sloc : Source_Location) return Token_Type;
   ${ada_doc('langkit.unit_lookup_token', 3)}

   procedure Dump_Lexical_Env (Unit : Analysis_Unit);
   --  Debug helper: output the lexical envs for given analysis unit

   procedure Trigger_Envs_Debug (Is_Active : Boolean);
   --  Activate debug traces for lexical envs lookups

   procedure Print (Unit : Analysis_Unit; Show_Slocs : Boolean := True);
   --  Debug helper: output the AST and eventual diagnostic for this unit on
   --  standard output.
   --
   --  If Show_Slocs, include AST nodes' source locations in the output.

   procedure PP_Trivia (Unit : Analysis_Unit);
   --  Debug helper: output a minimal AST with mixed trivias

   ${entities.decls2()}

   -----------------------
   -- Enumeration types --
   -----------------------

   function Image (Value : Boolean) return String;

   -----------------
   -- Array types --
   -----------------

   % for array_type in ctx.sorted_types(ctx.array_types):
      % if array_type._exposed:
         ${array_types.public_api_decl(array_type)}
      % endif
   % endfor

   --------------------
   -- Token Iterator --
   --------------------

   type Token_Iterator is private
      with Iterable => (First       => First_Token,
                        Next        => Next_Token,
                        Has_Element => Has_Element,
                        Element     => Element);
   --  Allow iteration on a range of tokens corresponding to a node

   function First_Token (Self : Token_Iterator) return Token_Type;
   --  Return the first token corresponding to the node

   function Next_Token
     (Self : Token_Iterator; Tok : Token_Type) return Token_Type;
   --  Return the token that follows Tok in the token stream

   function Has_Element
     (Self : Token_Iterator; Tok : Token_Type) return Boolean;
   --  Return if Tok is in Self's iteration range

   function Element (Self : Token_Iterator; Tok : Token_Type) return Token_Type;
   --  Identity function: helper for the Iterable aspect

   ${entities.decls3()}

   --  TODO??? Hide these from the public API

   pragma Warnings (Off, "defined after private extension");
   function Create_Entity
     (Node   : Implementation.${root_node_type_name};
      E_Info : Implementation.AST_Envs.Entity_Info
        := Implementation.AST_Envs.No_Entity_Info)
   return ${root_entity.api_name};
   pragma Warnings (On, "defined after private extension");

   function Bare_Node
     (Node : ${root_entity.api_name}'Class)
      return Implementation.${root_node_type_name};

   function To_Unit
     (Unit : Implementation.Internal_Unit) return Analysis_Unit;

   function To_Context
     (Context : Implementation.Internal_Context) return Analysis_Context;

   function Bare_Context
     (Context : Analysis_Context) return Implementation.Internal_Context;

   function Bare_Unit
     (Unit : Analysis_Unit) return Implementation.Internal_Unit;

private

   type Analysis_Context is access all Implementation.Analysis_Context_Type;
   type Analysis_Unit is access all Implementation.Analysis_Unit_Type;

   No_Analysis_Unit    : constant Analysis_Unit := null;
   No_Analysis_Context : constant Analysis_Context := null;

   --------------------------
   -- AST nodes (internal) --
   --------------------------

   <% md_fields = T.env_md.get_fields() %>

   type Public_Metadata is
      % if md_fields:
         record
            % for f in md_fields:
               % if f.type.is_bool_type:
                  ${f.name} : Boolean := False;
               % elif f.type.is_ast_node:
                  ${f.name} : System.Address := System.Null_Address;
               % else:
                  <% assert False %>
               % endif
            % endfor
         end record
            with Convention => C;
      % else:
         null record
            with Convention => C;
      % endif;

   No_Public_Metadata : constant Public_Metadata :=
      % if md_fields:
         (others => <>);
      % else:
         (null record);
      % endif

   type Public_Entity_Info is record
      MD         : Public_Metadata;
      Rebindings : System.Address;
   end record;

   No_Public_Entity_Info : constant Public_Entity_Info :=
     (No_Public_Metadata, System.Null_Address);

   % for e in ctx.entity_types:
      % if e.is_root_type:
         type ${e.api_name} is tagged record
            Node   : access Implementation.${root_node_value_type}'Class;
            E_Info : Public_Entity_Info;
         end record;
      % else:
         type ${e.api_name} is new ${e.base.api_name} with null record;
      % endif
      No_${e.api_name} : constant ${e.api_name} :=
        (null, No_Public_Entity_Info);
   % endfor

   --------------------------------
   -- Token Iterator (internals) --
   --------------------------------

   type Token_Iterator is record
      Node : ${root_entity.api_name};
      Last : Token_Index;
   end record;

   function To_Unit
     (Unit : Implementation.Internal_Unit) return Analysis_Unit
   is
     (Analysis_Unit (Unit));

   function To_Context
     (Context : Implementation.Internal_Context) return Analysis_Context
   is
     (Analysis_Context (Context));

   function Bare_Context
     (Context : Analysis_Context) return Implementation.Internal_Context
   is
     (Implementation.Internal_Context (Context));

   function Bare_Unit
     (Unit : Analysis_Unit) return Implementation.Internal_Unit
   is
     (Implementation.Internal_Unit (Unit));

end ${ada_lib_name}.Analysis;
