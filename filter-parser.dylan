module: packet-filter

define function extract-action
    (token-string :: <byte-string>,
     token-start :: <integer>, 	 
     token-end :: <integer>) 	 
 => (result :: <byte-string>); 	 
  copy-sequence(token-string, start: token-start, end: token-end);
end;


define constant $filter-tokens
  = simple-lexical-definition
      inert "([ \t]+)";

      token EOF;
      token AMP = "&";
      token PIPE = "\\|";
      token TILDE = "~";
      token EQUALS = "=";
      token DOT = "\\.";
      token LPAREN = "\\(";
      token RPAREN = "\\)";
      token COLON = ":";

      token Name = "[a-zA-Z_0-9-]+",
         semantic-value-function: extract-action;
end;

define constant $filter-productions
 = simple-grammar-productions
  production value => [Name value], action:
    method(p :: <simple-parser>, data, s, e)
        concatenate(p[0], p[1]);
    end;

  production value => [DOT value], action:
    method(p :: <simple-parser>, data, s, e)
        concatenate(".", p[1]);
    end;
  production value => [COLON value], action:
    method(p :: <simple-parser>, data, s, e)
        concatenate(":", p[1]);
    end;

  production value => [], action:
    method(p :: <simple-parser>, data, s, e)
        "";
    end;

  production filter => [LPAREN filter RPAREN AMP LPAREN filter RPAREN], action:
    method(p :: <simple-parser>, data, s, e)
        make(<and-expression>, left: p[1], right: p[5]);
    end;

  production filter => [LPAREN filter RPAREN PIPE LPAREN filter RPAREN], action:
    method(p :: <simple-parser>, data, s, e)
        make(<or-expression>, left: p[1], right: p[5]);
    end;

  production filter => [TILDE LPAREN filter RPAREN], action:
    method(p :: <simple-parser>, data, s, e)
        make(<not-expression>, left: p[2]);
    end;

//  production filter => [Name], action:
//    method(p :: <simple-parser>, data, s, e)
//        make(<frame-present>, frame: p[0]);
//    end;

  production filter => [Name DOT Name EQUALS value], action:
    method(p :: <simple-parser>, data, s, e)
        make(<field-equals>,
             frame: as(<symbol>, p[0]),
             name: as(<symbol>, p[2]),
             value: p[4]);
    end;

  production compound-filter => [filter], action:
    method(p :: <simple-parser>, data, s, e)
        data.filter := p[0];
    end;
end;

define constant $filter-automaton
  = simple-parser-automaton($filter-tokens, $filter-productions,
                            #[#"compound-filter"]);

define function consume-token 	 
    (consumer-data,
     token-number :: <integer>,
     token-name :: <object>,
     semantic-value :: <object>,
     start-position :: <integer>,
     end-position :: <integer>)
 => ();
  //let srcloc
  //  = range-source-location(consumer-data, start-position, end-position);
  format-out("%d - %d: token %d: %= value %=\n",
             start-position,
             end-position,
             token-number,
             token-name,
             semantic-value);
end function;

define class <filter> (<object>)
  slot filter :: <filter-expression>
end;

define function main ()
  let rangemap = make(<source-location-rangemap>);
  let scanner = make(<simple-lexical-scanner>,
                     definition: $filter-tokens,
                     rangemap: rangemap);
  let input = "ip.source-address = 23.23.23.23"; // & tcp.source-port = 23";
  let data = make(<filter>);
  let parser = make(<simple-parser>,
                    automaton: $filter-automaton,
                    start-symbol: #"compound-filter",
                    rangemap: rangemap,
                    consumer-data: data);
  scan-tokens(scanner,
              simple-parser-consume-token,
//              consume-token,
              parser,
              input,
              end: input.size,
              partial?: #f);
  scan-tokens(scanner, simple-parser-consume-token, parser, "", partial?: #f);
  let end-position = scanner.scanner-source-position;
  simple-parser-consume-token(parser, 0, #"EOF", parser, end-position, end-position);
  let filter = data.filter;
  print-filter(filter);
end;

define method print-filter (filter :: <frame-present>)
  format-out("frame present filter %=\n", filter.frame-name);
end;

define method print-filter (filter :: <field-equals>)
  format-out("field equals filter %= %= %=\n",
             filter.frame-name,
             filter.field-name,
             filter.field-value);
end;

define method print-filter (filter :: <and-expression>)
  format-out("and filter:");
  print-filter(filter.left-expression);
  print-filter(filter.right-expression);
end;

define method print-filter (filter :: <or-expression>)
  format-out("or filter: ");
  print-filter(filter.left-expression);
  print-filter(filter.right-expression);
end;

define method print-filter (filter :: <not-expression>)
  format-out("not filter: ");
  print-filter(filter.expression);
end;
