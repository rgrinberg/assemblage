(*
 * Copyright (c) 2014 Daniel C. Bünzli
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** Assemblage log.

    For documentation see {!Assemblage.Log}. *)

(** {1 Log level and output} *)

type level = Show | Error | Warning | Info | Debug

val level : unit -> level option
val set_level : level option -> unit
val set_formatter : [`All | `Level of level ] -> Format.formatter -> unit

(** {1 Logging} *)

val msg : ?header:string -> level ->
  ('a, Format.formatter, unit, unit) format4 -> 'a

val msg_driver_fault : ?header:string -> level ->
  ('a, Format.formatter, unit, unit) format4 -> 'a

val kmsg : ?header:string ->
  (unit -> 'a) -> level -> ('b, Format.formatter, unit, 'a) format4 -> 'b

val show : ?header:string -> ('a, Format.formatter, unit, unit) format4 -> 'a
val err : ?header:string -> ('a, Format.formatter, unit, unit) format4 -> 'a
val warn : ?header:string -> ('a, Format.formatter, unit, unit) format4 -> 'a
val info : ?header:string -> ('a, Format.formatter, unit, unit) format4 -> 'a
val debug : ?header:string -> ('a, Format.formatter, unit, unit) format4 -> 'a

(** {1 Log monitoring} *)

val err_count : unit -> int
val warn_count : unit -> int