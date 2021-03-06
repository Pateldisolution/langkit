## vim: filetype=makoada

with Ada.Strings.Unbounded;           use Ada.Strings.Unbounded;
with Ada.Strings.Wide_Wide_Unbounded; use Ada.Strings.Wide_Wide_Unbounded;

with Langkit_Support.Slocs; use Langkit_Support.Slocs;
with Langkit_Support.Text;  use Langkit_Support.Text;

with ${ada_lib_name}.Common;         use ${ada_lib_name}.Common;
with ${ada_lib_name}.Implementation; use ${ada_lib_name}.Implementation;

private package ${ada_lib_name}.Unparsing_Implementation is

   type Unparsing_Buffer is limited record
      Content : Unbounded_Wide_Wide_String;
      --  Append-only text buffer for the unparsed tree

      Last_Sloc : Source_Location := (1, 1);
      --  Source location of the next character to append to Content

      Last_Token : Token_Kind;
      --  If Content is not emply, kind of the last token/trivia that was
      --  unparsed. Undefined otherwise.
   end record;

   procedure Append
     (Buffer : in out Unparsing_Buffer; Char : Wide_Wide_Character);

   procedure Append
     (Buffer : in out Unparsing_Buffer;
      Kind   : Token_Kind;
      Text   : Text_Type)
      with Pre => Text'Length > 0;
   --  Append Text, to unparse the given token Kind, to Buffer, updating
   --  Buffer.Last_Sloc and Buffer.Last_Token accordingly.

   procedure Apply_Spacing_Rules
     (Buffer     : in out Unparsing_Buffer;
      Next_Token : Token_Kind);
   --  Add a whitespace or a newline to buffer if mandated by spacing rules
   --  given the next token to emit.

   function Unparse
     (Node                : access Abstract_Node_Type'Class;
      Unit                : Internal_Unit;
      Preserve_Formatting : Boolean;
      As_Unit             : Boolean) return String;
   --  Turn the Node tree into a string that can be re-parsed to yield the same
   --  tree (source locations excepted). The encoding used is the same as the
   --  one that was used to parse Node's analysis unit.
   --
   --  If Preserve_Formatting is true, use token/trivia information when
   --  available to preserve original source code formatting.
   --
   --  If As_Unit is true, consider that Node is the root of Unit in order to
   --  preserve the formatting of leading/trailing tokens/trivia. Note that
   --  this has no effect unless Preserve_Formatting itself is true.

   function Unparse
     (Node                : access Abstract_Node_Type'Class;
      Unit                : Internal_Unit;
      Preserve_Formatting : Boolean;
      As_Unit             : Boolean) return String_Access;
   --  Likewise, but return a string access. Callers must deallocate the result
   --  when done with it.

   function Unparse
     (Node                : access Abstract_Node_Type'Class;
      Preserve_Formatting : Boolean) return Text_Type;
   --  Likewise, but return a text access. Callers must deallocate the result
   --  when done with it.

   ----------------------
   -- Unparsing tables --
   ----------------------

   --  At the token level

   type Token_Unparser is record
      Kind : Token_Kind;
      --  Token kind, which is what is used most of the time to determine the
      --  text to emit for a token.

      Text : Text_Cst_Access;
      --  Sometimes, we must emit a token whose kind is not associated to a
      --  specific literal: for such token kinds, this must be the text to emit
      --  for that token.
   end record;

   type Token_Sequence is array (Positive range <>) of Token_Unparser;
   type Token_Sequence_Access is access constant Token_Sequence;
   type Token_Sequence_Access_Array is
      array (Positive range <>) of Token_Sequence_Access;

   Empty_Token_Sequence : aliased constant Token_Sequence := (1 .. 0 => <>);

   --  At the node field level

   type Field_Unparser is record
      Pre_Tokens, Post_Tokens : Token_Sequence_Access;
      --  Lists of tokens to emit before, and after unparsing some node field

      Empty_List_Is_Absent : Boolean;
      --  Whether this field is to be considered as absent when it is an empty
      --  list node.
   end record;

   type Field_Unparser_Array is array (Positive range <>) of Field_Unparser;

   Empty_Field_Unparser : aliased constant Field_Unparser :=
     (Empty_Token_Sequence'Access, Empty_Token_Sequence'Access, False);

   type Field_Unparser_List (N : Natural) is record
      Field_Unparsers : Field_Unparser_Array (1 .. N);
      --  For each field in the node, describe how to unparse it when it's
      --  present. Nothing must be emitted when it's absent.

      Inter_Tokens    : Token_Sequence_Access_Array (1 .. N);
      --  Inter_Tokens (I) specifies the list of tokens to emit after unparsing
      --  field I-1 and field I. When it exists, Inter_Tokens (1) is always
      --  Empty_Token_Sequence'Access.
   end record;
   --  Unparsing table for the fields corresponding to a specific regular node

   type Field_Unparser_List_Access is access constant Field_Unparser_List;

   Empty_Field_Unparser_List : aliased constant Field_Unparser_List :=
     (N => 0, others => <>);

   --  At the node level

   type Node_Unparser_Kind is (Regular, List, Token);

   type Node_Unparser (Kind : Node_Unparser_Kind := Regular) is record
      case Kind is
         when Regular =>
            Pre_Tokens : Token_Sequence_Access;
            --  List of tokens to emit first when unparsing this node

            Field_Unparsers : Field_Unparser_List_Access;
            --  Description of how to unparse fields

            Post_Tokens : Token_Sequence_Access;
            --  List of tokens to emit after fields are unparsed

         when List =>
            Has_Separator : Boolean;
            --  Whether to emit a token between two list items

            Separator : Token_Unparser;
            --  If Has_Separator is true, describe what separator token to emit
            --  between two list items.

         when Token =>
            null;
      end case;
   end record;
   --  Unparsing descriptor for a non-abstract and non-synthetic node

   subtype Regular_Node_Unparser is Node_Unparser (Regular);
   subtype List_Node_Unparser is Node_Unparser (List);
   subtype Token_Node_Unparser is Node_Unparser (Token);

   type Node_Unparser_Map is array (${root_node_kind_name}) of Node_Unparser;
   type Node_Unparser_Map_Access is access constant Node_Unparser_Map;

   Node_Unparsers : Node_Unparser_Map_Access;
   --  Unparsing table, describing how to unparse all parse nodes in
   --  ${ctx.lang_name}.
   ## TODO??? how can we make this constant without exposing the underlying
   ## array?

end ${ada_lib_name}.Unparsing_Implementation;
