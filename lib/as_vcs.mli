(*
 * Copyright (c) 2015 Daniel C. Bünzli
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

open Bos

type t = [ `Git | `Hg ]

val override_kind : unit -> t option
val set_override_kind : t option -> unit
val override_exec : unit -> string option
val set_override_exec : string option -> unit

val exists : path -> t -> bool Bos.OS.result
val find : path -> t option Bos.OS.result
val get : path -> t Bos.OS.result
val head : ?dirty:bool -> path -> t -> string Bos.OS.result
val describe : ?dirty:bool -> path -> t -> string Bos.OS.result
