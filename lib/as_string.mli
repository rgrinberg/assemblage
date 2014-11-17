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

(** String utilities and string sets

    For documentation see {!Assemblage.String}. *)

include module type of String

val split : sep:string -> string -> string list
(** [split sep s] is the list of all (possibly empty)
    substrings of [s] that are delimited by matches of the non empty
    separator string [sep].

    Matching separators in [s] starts from the beginning of [s] and once
    one is found, the separator is skipped and matching starts again
    (i.e. separator matches can't overlap). If there is no separator
    match in [s], [[s]] is returned.

    The invariants [String.concat sep (String.split sep s) = s] and
    [String.split sep s <> []] always hold.

    @raise Invalid_argument if [sep] is the empty string. *)

val rsplit : sep:string -> string -> string list
(** [rsplit sep s] is like {!split} but the matching is
    done backwards, starting from the end of [s].

    @raise Invalid_argument if [sep] is the empty string. *)

val cut : sep:string -> string -> (string * string) option
(** [cut sep s] is either the pair [Some (l,r)] of the two
    (possibly empty) substrings of [s] that are delimited by the first
    match of the non empty separator string [sep] or [None] if [sep]
    can't be matched in [s]. Matching starts from the beginning of [s].

    The invariant [l ^ sep ^ r = s] holds.

    @raise Invalid_argument if [sep] is the empty string. *)

val rcut : sep:string -> string -> (string * string) option
(** [rcut sep s] is like {!cut} but the matching is done backwards
    starting from the end of [s].

    @raise Invalid_argument if [sep] is the empty string. *)

val slice : ?start:int -> ?stop:int -> string -> string
(** [slice ~start ~stop s] is the string s.[start], s.[start+1], ...
    s.[stop - 1]. [start] defaults to [0] and [stop] to [String.length s].

    If [start] or [stop] are negative they are subtracted from
    [String.length s]. This means that [-1] denotes the last
    character of the string. *)

val tokens : string -> string list
(** [tokens s] is the list of non empty strings made of characters
    that are not separated by [' '], ['\t'], ['\n'], ['\r'] characters in
    [s], the order of character appearance in the list is the same as
    in [s]. *)

val uniquify : string list -> string list
(** [uniquify ss] is [ss] without duplicates, the list order is preserved. *)

(** {1 Sets of strings} *)

module Set : sig
  include Set.S with type elt = string
  val of_list : string list -> t
  (** [of_list ss] is a set from the list [ss]. *)
end

val make_unique_in : ?suff:string -> Set.t -> string -> string option
(** [make_unique_in ~suff set elt] is a string that does not belong
    [set].  If [elt] in not in [set] then this is [elt] itself
    otherwise it is a string defined by [Printf.sprintf "%s%s%d" s
    suff d] where [d] is a positive number starting from [1]. [suff]
    defaults to ["~"].  [None] in the unlikely case that all positive
    numbers were exhausted. *)

module Map : sig
  include Map.S with type key = string
  val dom : 'a t -> Set.t
  (** [dom m] is the domain of [m]. *)
end
