-- VHDL Entity R6502_TC.FSM_NMI.symbol
--
-- Created:
--          by - eda.UNKNOWN (ENTWICKL4-XP-PR)
--          at - 22:43:05 04.01.2009
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2007.1a (Build 13)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

entity FSM_NMI is
   port( 
      clk_clk_i   : in     std_logic;
      fetch_i     : in     std_logic;
      nmi_n_i     : in     std_logic;
      rst_rst_n_i : in     std_logic;
      nmi_o       : out    std_logic
   );

-- Declarations

end FSM_NMI ;

-- Jens-D. Gutschmidt     Project:  R6502_TC  

-- scantara2003@yahoo.de                      

-- COPYRIGHT (C) 2008 by Jens Gutschmidt and OPENCORES.ORG                                                                                     

--                                                                                                                                             

-- This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by   

-- the Free Software Foundation, either version 3 of the License, or any later version.                                                        

--                                                                                                                                             

-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of              

-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.                                  

--                                                                                                                                             

-- You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.     

--                                                                                                                                             

-- CVS Revisins History                                                                                                                        

--                                                                                                                                             

-- $Log: not supported by cvs2svn $                                                                                                                            

--   <<-- more -->>                                                                                                                            

-- Title:  FSM for NMI  

-- Path:  R6502_TC/FSM_NMI/fsm  

-- Edited:  by eda on 03 Jan 2009  

--
-- VHDL Architecture R6502_TC.FSM_NMI.fsm
--
-- Created:
--          by - eda.UNKNOWN (ENTWICKL4-XP-PR)
--          at - 22:43:05 04.01.2009
--
-- Generated by Mentor Graphics' HDL Designer(TM) 2007.1a (Build 13)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
 
architecture fsm of FSM_NMI is

   type state_type is (
      idle,
      idle1,
      idle2,
      IMP
   );
 
   -- State vector declaration
   attribute state_vector : string;
   attribute state_vector of fsm : architecture is "current_state";

   -- Declare current and next state signals
   signal current_state : state_type;
   signal next_state : state_type;

   -- Declare any pre-registered internal signals
   signal nmi_o_cld : std_logic ;

begin

   -----------------------------------------------------------------
   clocked_proc : process ( 
      clk_clk_i,
      rst_rst_n_i
   )
   -----------------------------------------------------------------
   begin
      if (rst_rst_n_i = '0') then
         current_state <= idle;
         -- Default Reset Values
         nmi_o_cld <= '0';
      elsif (clk_clk_i'event and clk_clk_i = '1') then
         current_state <= next_state;
         -- Default Assignment To Internals
         nmi_o_cld <= '0';

         -- Combined Actions
         case current_state is
            when IMP => 
               nmi_o_cld <= '1';
            when others =>
               null;
         end case;
      end if;
   end process clocked_proc;
 
   -----------------------------------------------------------------
   nextstate_proc : process ( 
      current_state,
      fetch_i,
      nmi_n_i
   )
   -----------------------------------------------------------------
   begin
      case current_state is
         -- <<< REQ1
         when idle => 
            if (nmi_n_i = '1') then 
               next_state <= idle1;
            else
               next_state <= idle;
            end if;
         when idle1 => 
            if (nmi_n_i = '0') then 
               next_state <= idle2;
            else
               next_state <= idle1;
            end if;
         when idle2 => 
            if (nmi_n_i = '0') then 
               next_state <= IMP;
            else
               next_state <= idle;
            end if;
         when IMP => 
            if (fetch_i = '1') then 
               next_state <= idle;
            else
               next_state <= IMP;
            end if;
         when others =>
            next_state <= idle;
      end case;
   end process nextstate_proc;
 
   -- Concurrent Statements
   -- Clocked output assignments
   nmi_o <= nmi_o_cld;
end fsm;