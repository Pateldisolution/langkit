with Ada.Text_IO; use Ada.Text_IO;

package body Support is

   --------------------------
   -- Raise_Property_Error --
   --------------------------

   procedure Raise_Property_Error (Message : String := "") is
   begin
      raise Property_Error with Message;
   end Raise_Property_Error;

   --------------
   -- Put_Line --
   --------------

   procedure Put_Line (Elements : Envs.Entity_Array) is
   begin
      if Elements'Length = 0 then
         Put_Line ("  <none>");
      else
         for E of Elements loop
            declare
               Img : constant Text_Type := Envs.Text_Image (E.Info.Rebindings);
            begin
               Put_Line ("  * '" & E.Node & "' " & Image (Img));
            end;
         end loop;
      end if;
   end Put_Line;

end Support;
