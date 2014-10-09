(*
 * Copyright (c) 2014 Daniel C. Bünzli.
 * Copyright (c) 2014 Thomas Gazagnaire <thomas@gazagnaire.org>
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

(** Execution of shell commands. *)

(** {1 Execute commands} *)

val verbose_default : bool ref
(** [verbose_default] defines the default value for the [?verbose] argument
    of this module. *)

val has_cmd : string -> bool
(** [has_cmd cmd] is [true] iff the shell has the command [cmd]. *)

val exec : ?verbose:bool -> ('a, unit, string, unit) format4 -> 'a
(** Execute a shell command. *)

val exec_output : ?verbose:bool -> ('a, unit, string, string list) format4 -> 'a
(** Execute a shell command and returns its output. *)

val try_exec : ('a, unit, string, bool) format4 -> 'a
(** Try to run a given command. *)

val in_dir : string -> (unit -> 'a) -> 'a
(** Execute a command in a given directory. *)
