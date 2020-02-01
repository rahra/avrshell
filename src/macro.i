/* Copyright 2019-2020 Bernhard R. Fischer, 4096R/8E24F29D <bf@abenteuerland.at>
 *
 * This file is part of AVRshell.
 *
 * Smrender is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * Smrender is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with smrender. If not, see <http://www.gnu.org/licenses/>.
 */

; macro to push multiple registers in a sequence to the stack
.macro pushm reg0 reg1
   push  \reg0
.if \reg1-\reg0
   pushm "(\reg0+1)",\reg1
.endif
.endm

; macro to pop multiple registers in a sequence off the stack
.macro popm reg0 reg1
   pop   \reg1
.if \reg1-\reg0
   popm  \reg0,"(\reg1-1)"
.endif
.endm

