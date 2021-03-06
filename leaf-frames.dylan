module: binary-data
author: Andreas Bogk and Hannes Mehnert
copyright: 2005-2011 Andreas Bogk and Hannes Mehnert. All rights reserved.
license: see LICENSE.txt in this distribution

define abstract class <leaf-frame> (<frame>)
end;

define method print-object (object :: <leaf-frame>, stream :: <stream>) => ()
  write(stream, as(<string>, object));
end;

define abstract class <fixed-size-untranslated-leaf-frame>
    (<leaf-frame>, <fixed-size-untranslated-frame>)
end;

define abstract class <variable-size-untranslated-leaf-frame>
    (<leaf-frame>, <variable-size-untranslated-frame>)
end;

define open abstract class <fixed-size-translated-leaf-frame>
    (<leaf-frame>, <fixed-size-frame>, <translated-frame>)
end;

define abstract class <variable-size-translated-leaf-frame>
    (<leaf-frame>, <variable-size-frame>, <translated-frame>)
end;

define open generic read-frame
    (frame-type :: subclass(<leaf-frame>), string :: <string>) => (frame);

define method read-frame
    (frame-type :: subclass(<leaf-frame>), string :: <string>)
 => (frame)
  error("read-frame not supported for frame-type %=", frame-type);
end;

define class <boolean-bit> (<fixed-size-translated-leaf-frame>) end;

define method parse-frame
    (frame-type == <boolean-bit>, packet :: <byte-sequence>, #key)
 => (value :: <boolean>, next-unparsed :: <integer>)
  let subseq = subsequence(packet, length: 1);
  let value = decode-integer(subseq, 1);
  values(if (value == 1) #t else #f end, 1)
end;

define method assemble-frame-into-as
    (frame-type == <boolean-bit>,
     data :: <boolean>,
     packet :: <byte-sequence>)
 => (end-offset :: <integer>)
  let subseq = subsequence(packet, length: 1);
  if (data)
    encode-integer(1, subseq, 1);
  else
    encode-integer(0, subseq, 1);
  end;
  1;
end;

define inline method field-size (type == <boolean-bit>)
 => (length :: <integer>)
  1
end;

define method read-frame
    (type == <boolean-bit>, string :: <string>)
 => (res)
  string = "#t" | string = "true"
end;

define inline method high-level-type (low-level-type == <boolean-bit>)
 => (res == <boolean>)
  <boolean>;
end;

define class <unsigned-byte> (<fixed-size-translated-leaf-frame>)
end;

define method parse-frame
    (frame-type == <unsigned-byte>, packet :: <byte-sequence>, #key)
 => (value :: <byte>, next-unparsed :: <integer>)
  values(packet[0], 8)
end;

define method assemble-frame-into-as
    (frame-type == <unsigned-byte>,
     data :: <byte>,
     packet :: <stretchy-byte-vector-subsequence>)
 => (end-offset :: <integer>)
  packet[0] := data;
  8
end;

define inline method field-size (type == <unsigned-byte>)
 => (length :: <integer>)
  8
end;

define method read-frame (type == <unsigned-byte>, string :: <string>)
 => (res)
  let res = string-to-integer(string);
  if (res < 0 | res > (2 ^ field-size(type) - 1))
    signal(make(<out-of-range-error>))
  end;
  res
end;

define inline method high-level-type (low-level-type == <unsigned-byte>)
 => (res == <byte>)
  <byte>
end;


define open abstract class <unsigned-integer-bit-frame> (<fixed-size-translated-leaf-frame>)
end;

define macro n-bit-unsigned-integer-definer
    { define n-bit-unsigned-integer(?:name; ?n:*) end }
     => { define class ?name (<unsigned-integer-bit-frame>)
            slot data :: limited(<integer>, min: 0, max: 2 ^ ?n - 1),
              required-init-keyword: data:;
          end;

          define inline method high-level-type (low-level-type == ?name)
           => (res :: <type>)
            limited(<integer>, min: 0, max: 2 ^ ?n - 1)
          end;

          define inline method field-size (type == ?name)
           => (length :: <integer>)
            ?n
          end; }
end;

define n-bit-unsigned-integer(<1bit-unsigned-integer>; 1) end;
define n-bit-unsigned-integer(<2bit-unsigned-integer>; 2) end;
define n-bit-unsigned-integer(<3bit-unsigned-integer>; 3) end;
define n-bit-unsigned-integer(<4bit-unsigned-integer>; 4) end;
define n-bit-unsigned-integer(<5bit-unsigned-integer>; 5) end;
define n-bit-unsigned-integer(<6bit-unsigned-integer>; 6) end;
define n-bit-unsigned-integer(<7bit-unsigned-integer>; 7) end;
define n-bit-unsigned-integer(<9bit-unsigned-integer>; 9) end;
define n-bit-unsigned-integer(<10bit-unsigned-integer>; 10) end;
define n-bit-unsigned-integer(<11bit-unsigned-integer>; 11) end;
define n-bit-unsigned-integer(<12bit-unsigned-integer>; 12) end;
define n-bit-unsigned-integer(<13bit-unsigned-integer>; 13) end;
define n-bit-unsigned-integer(<14bit-unsigned-integer>; 14) end;
define n-bit-unsigned-integer(<15bit-unsigned-integer>; 15) end;

define n-bit-unsigned-integer(<20bit-unsigned-integer>; 20) end;

define method parse-frame
    (frame-type :: subclass(<unsigned-integer-bit-frame>),
     packet :: <byte-sequence>,
     #key)
 => (value :: <integer>, next-unparsed :: <integer>)
  let result-size = field-size(frame-type);
  let subseq = subsequence(packet, length: result-size);
  let value = decode-integer(subseq, result-size);
  values(value, result-size)
end;

define method assemble-frame-into-as
    (frame-type :: subclass(<unsigned-integer-bit-frame>),
     data :: <integer>,
     packet :: <stretchy-vector-subsequence>)
 => (res :: <integer>)
  let result-size = field-size(frame-type);
  let subseq = subsequence(packet, length: result-size);
  encode-integer(data, subseq, result-size);
  result-size
end;

define method as (class == <string>, frame :: <unsigned-integer-bit-frame>)
 => (string :: <string>)
  concatenate("0x",
              integer-to-string(frame.data,
                                base: 16,
                                size: byte-offset(frame-size(frame) + 7) * 2))
end;

define method read-frame (type :: subclass(<unsigned-integer-bit-frame>),
                          string :: <string>)
 => (res)
  let res = string-to-integer(string);
  if (res < 0 | res > (2 ^ field-size(type) - 1))
    signal(make(<out-of-range-error>))
  end;
  res
end;

// A completely empty frame.
define class <null-frame> (<fixed-size-untranslated-leaf-frame>)
end;

define constant $null-frame = make(<null-frame>);

define inline method field-size (type == <null-frame>)
  => (length :: <integer>)
  0
end;

define method parse-frame
    (type == <null-frame>, packet :: <byte-sequence>, #key)
  => (result :: <null-frame>, consumed-bits :: <integer>)
  values($null-frame, 0);
end;

define method assemble-frame-into
    (frame :: <null-frame>, packet :: <stretchy-byte-vector-subsequence>)
  => (length :: <integer>)
  0
end;

define open abstract class <fixed-size-byte-vector-frame> (<fixed-size-untranslated-leaf-frame>)
  slot data :: <byte-sequence>, required-init-keyword: data:;
end;

define macro n-byte-vector-definer
  { define n-byte-vector(?:name, ?n:*) end }
    => { define class ?name (<fixed-size-byte-vector-frame>)
         end;

         define inline method field-size (type == ?name)
          => (length :: <integer>)
           ?n * 8
         end;

         define leaf-frame-constructor(?name) end;
       }
end;

define sealed domain parse-frame (subclass(<fixed-size-byte-vector-frame>),
                                  <byte-sequence>);

define method parse-frame
    (frame-type :: subclass(<fixed-size-byte-vector-frame>),
     packet :: <byte-sequence>,
     #key)
 => (frame :: <fixed-size-byte-vector-frame>, next-unparsed :: <integer>)
  let end-of-frame = field-size(frame-type);
  if (packet.size < byte-offset(end-of-frame))
    signal(make(<malformed-data-error>))
  else
    values(make(frame-type,
                data: packet),
           end-of-frame)
  end;
end;

define method assemble-frame-into
    (frame :: <fixed-size-byte-vector-frame>,
     packet :: <stretchy-byte-vector-subsequence>)
 => (res :: <integer>)
  copy-bytes(packet, 0, frame.data, 0, byte-offset(frame-size(frame)));
  frame-size(frame)
end;

define method as (class == <string>, frame :: <fixed-size-byte-vector-frame>)
 => (res :: <string>)
  let out-stream = make(<string-stream>, direction: #"output");
  block ()
    hexdump(out-stream, frame.data);
    out-stream.stream-contents;
  cleanup
    close(out-stream)
  end
end;

define method read-frame
    (frame-type :: subclass(<fixed-size-byte-vector-frame>),
     string :: <string>)
 => (res)
  make(frame-type,
       data: copy-sequence(string,
                           start: 0,
                           end: byte-offset(field-size(frame-type))))
end;

define method \= (frame1 :: <fixed-size-byte-vector-frame>,
                  frame2 :: <fixed-size-byte-vector-frame>)
 => (result :: <boolean>)
  frame1.data = frame2.data
end method;

define open abstract class <big-endian-unsigned-integer-byte-frame> (<fixed-size-translated-leaf-frame>)
  //slot data :: <integer>, required-init-keyword: data:;
end;

define open abstract class <little-endian-unsigned-integer-byte-frame> (<fixed-size-translated-leaf-frame>)
end;

define macro n-byte-unsigned-integer-definer
    { define n-byte-unsigned-integer(?:name; ?n:*) end }
     => { define class ?name ## "-big-endian-unsigned-integer>"
                 (<big-endian-unsigned-integer-byte-frame>)
            slot data :: limited(<integer>, min: 0, max: 2 ^ (8 * ?n) - 1),
              required-init-keyword: data:;
          end;

          define inline method high-level-type
              (low-level-type == ?name ## "-big-endian-unsigned-integer>")
           => (res :: <type>)
            limited(<integer>, min: 0, max: 2 ^ (8 * ?n) - 1);
          end;

          define inline method field-size
              (field == ?name ## "-big-endian-unsigned-integer>")
           => (length :: <integer>)
            ?n * 8
          end;

          define class ?name ## "-little-endian-unsigned-integer>"
                 (<little-endian-unsigned-integer-byte-frame>)
            slot data :: limited(<integer>, min: 0, max: 2 ^ (8 * ?n) - 1),
              required-init-keyword: data:;
          end;

          define inline method high-level-type
              (low-level-type == ?name ## "-little-endian-unsigned-integer>")
           => (res :: <type>)
            limited(<integer>, min: 0, max: 2 ^ (8 * ?n) - 1);
          end;

          define inline method field-size
              (field == ?name ## "-little-endian-unsigned-integer>")
           => (length :: <integer>)
            ?n * 8
          end; }
end;

define n-byte-unsigned-integer(<2byte; 2) end;
define n-byte-unsigned-integer(<3byte; 3) end;
//define n-byte-unsigned-integer(<4byte; 4) end;

define sealed domain parse-frame
    (subclass(<big-endian-unsigned-integer-byte-frame>), <byte-sequence>);

define method parse-frame
    (frame-type :: subclass(<big-endian-unsigned-integer-byte-frame>),
     packet :: <byte-sequence>,
     #key)
 => (value :: <integer>, next-unparsed :: <integer>)
  let result-size = byte-offset(field-size(frame-type));
  if (packet.size < result-size)
    signal(make(<malformed-data-error>))
  else
    let result = 0;
    for (i from 0 below result-size)
      result := packet[i] + ash(result, 8)
    end;
    values(result, result-size * 8)
  end;
end;

define method assemble-frame-into-as
    (frame-type :: subclass(<big-endian-unsigned-integer-byte-frame>),
     data :: <integer>,
     packet :: <byte-sequence>)
 => (res :: <integer>)
  for (i from 0 below byte-offset(field-size(frame-type)))
    packet[i] := logand(#xff, ash(data, - (field-size(frame-type) - i * 8 - 8)));
  end;
  field-size(frame-type)
end;

define method as
    (class == <string>, frame :: <big-endian-unsigned-integer-byte-frame>)
 => (string :: <string>)
  concatenate("0x", integer-to-string(frame.data,
                                      base: 16,
                                      size: ash(2 * field-size(frame.object-class), -3)));
end;

define method read-frame
    (type :: subclass(<big-endian-unsigned-integer-byte-frame>),
     string :: <string>)
 => (res)
  let res = string-to-integer(string);
  if (res < 0 | res > (2 ^ field-size(type) - 1))
    signal(make(<out-of-range-error>))
  end;
  res
end;

define sealed domain parse-frame
    (subclass(<little-endian-unsigned-integer-byte-frame>), <byte-sequence>);

define method parse-frame
    (frame-type :: subclass(<little-endian-unsigned-integer-byte-frame>),
     packet :: <byte-sequence>,
     #key)
 => (value :: <integer>, next-unparsed :: <integer>)
  let result-size = byte-offset(field-size(frame-type));
  if (packet.size < result-size)
    signal(make(<malformed-data-error>))
  else
    let result = 0;
    for (i from result-size - 1 to 0 by -1)
      result := packet[i] + ash(result, 8)
    end;
    values(result, result-size * 8)
  end;
end;

define method assemble-frame-into-as
    (frame-type :: subclass(<little-endian-unsigned-integer-byte-frame>),
     data :: <integer>,
     packet :: <stretchy-byte-vector-subsequence>)
 => (res :: <integer>)
  for (i from 0 below byte-offset(field-size(frame-type)))
    packet[i] := logand(#xff, ash(data, - i * 8));
  end;
  field-size(frame-type)
end;

define method as
    (class == <string>, frame :: <little-endian-unsigned-integer-byte-frame>)
 => (string :: <string>)
  concatenate("0x", integer-to-string(frame.data,
                                      base: 16,
                                      size: ash(2 * field-size(frame.object-class), -3)))
end;

define method read-frame
    (type :: subclass(<little-endian-unsigned-integer-byte-frame>),
     string :: <string>)
 => (res)
  let res = string-to-integer(string);
  if (res < 0 | res > (2 ^ field-size(type) - 1))
    signal(make(<out-of-range-error>))
  end;
  res
end;


define abstract class <variable-size-byte-vector> (<variable-size-untranslated-leaf-frame>)
  slot data :: <byte-sequence>, required-init-keyword: data:;
  slot parent :: false-or(<container-frame>) = #f, init-keyword: parent:;
end;

define method frame-size (frame :: <variable-size-byte-vector>)
 => (res :: <integer>)
  frame.data.size * 8
end;

define method parse-frame
    (frame-type :: subclass(<variable-size-byte-vector>),
     packet :: <byte-sequence>,
     #key parent)
 => (frame :: <variable-size-byte-vector>, next-unparsed :: <integer>)
   values(make(frame-type, data: packet, parent: parent), packet.size * 8)
end;

define method assemble-frame-into
    (frame :: <variable-size-byte-vector>,
     packet :: <stretchy-byte-vector-subsequence>)
 => (res :: <integer>)
  copy-bytes(packet, 0, frame.data, 0, frame.data.size);
  frame-size(frame)
end;

define class <externally-delimited-string> (<variable-size-byte-vector>)
end;

define constant $empty-externally-delimited-string
  = make(<externally-delimited-string>, data: make(<byte-sequence>, capacity: 0));

define method as (class == <string>, frame :: <externally-delimited-string>)
 => (res :: <string>)
  let res = make(<string>, size: byte-offset(frame-size(frame)));
  copy-bytes(res, 0, frame.data, 0, byte-offset(frame-size(frame)));
  res
end;

define method as (class == <externally-delimited-string>, string :: <string>)
 => (res :: <externally-delimited-string>)
  let res = make(<externally-delimited-string>,
                 data: make(<byte-sequence>, capacity: string.size));
  copy-bytes(res.data, 0, string, 0, string.size);
  res
end;


define class <raw-frame> (<variable-size-byte-vector>)
end;

define constant $empty-raw-frame
  = make(<raw-frame>, data: make(<byte-sequence>, capacity: 0));

define method as (class == <string>, frame :: <raw-frame>) => (res :: <string>)
  let out-stream = make(<string-stream>, direction: #"output");
  block ()
    hexdump(out-stream, frame.data);
    out-stream.stream-contents
  cleanup
    close(out-stream)
  end
end;


define method as (class == <raw-frame>, bytes :: <collection>)
 => (res :: <raw-frame>)
  let sv = make(<raw-frame>,
                data: make(<byte-sequence>, capacity: bytes.size));
  copy-bytes(sv.data, 0, bytes, 0, bytes.size);
  sv
end;

define method read-frame (type == <raw-frame>,
                          string :: <string>)
 => (res)
  let res = make(<raw-frame>,
                 data: make(<byte-sequence>, capacity: string.size));
  copy-bytes(res.data, 0, string, 0, string.size);
  res
end;


define macro leaf-frame-constructor-definer
  { define leaf-frame-constructor("<" ## ?:name ## ">") end }
 =>
  {
    define method ?name (data :: <byte-vector>)
     => (res :: "<" ## ?name ## ">");
      parse-frame("<" ## ?name ## ">", data)
    end;

    define method ?name (data :: <collection>)
     => (res :: "<" ## ?name ## ">");
      ?name(as(<byte-vector>, data))
    end;

    define method ?name (data :: <string>)
     => (res :: "<" ## ?name ## ">");
      read-frame("<" ## ?name ## ">", data)
    end;

  }
end;

//FIXME
define n-byte-vector(<little-endian-unsigned-integer-4byte>, 4) end;
define n-byte-vector(<big-endian-unsigned-integer-4byte>, 4) end;


define function float-to-byte-vector-be (float :: <float>)
 => (res :: <byte-vector>)
  let res = make(<byte-vector>, size: 4, fill: 0);
  let r = float;
  for (i from 3 to 0 by -1)
    let (this, remainder) = floor/(r, 256);
    r := this;
    res[i] := floor(remainder);
  end;
  res
end;

define function float-to-byte-vector-le (float :: <float>)
 => (res :: <byte-vector>)
  let res = make(<byte-vector>, size: 4, fill: 0);
  let r = float;
  for (i from 0 below 4)
    let (this, remainder) = floor/(r, 256);
    r := this;
    res[i] := floor(remainder);
  end;
  res
end;

define function byte-vector-to-float-le
    (bv :: <stretchy-byte-vector-subsequence>)
 => (res :: <float>)
  let res = 0.0d0;
  for (ele in reverse(bv))
    res := ele + 256 * res;
  end;
  res
end;

define function byte-vector-to-float-be
    (bv :: <stretchy-byte-vector-subsequence>)
 => (res :: <float>)
  let res = 0.0d0;
  for (ele in bv)
    res := ele + 256 * res;
  end;
  res
end;

