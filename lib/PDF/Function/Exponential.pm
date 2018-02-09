use v6;

use PDF::Function;

#| /FunctionType 2 - Exponential
#| see [PDF 1.7 Section 3.9.2 Type 2 (Exponential Interpolation) Functions]
class PDF::Function::Exponential
    is PDF::Function {

    use PDF::DAO::Tie;
    # see [PDF 1.7 TABLE 3.37 Additional entries specific to a type 2 function dictionary]
    has Numeric @.C0 is entry;          #| (Optional) An array of n numbers defining the function result when x = 0.0. Default value: [ 0.0 ].
    has Numeric @.C1 is entry;          #| (Optional) An array of n numbers defining the function result when x = 1.0. Default value: [ 1.0 ].
    has Numeric $N is entry(:required); #| (Required) The interpolation exponent. Each input value x will return n values, given by yj = C0j + xN × (C1j − C0j ), for 0 ≤ j < n.

    class Interpreter
        is PDF::Function::Interpreter {
        has Numeric @.C0 is required;
        has Numeric @.C1 is required;
        has Numeric $.N is required;
        has UInt $!n;

        submethod TWEAK {
            die "domain should be of length 1"
                unless self.domain.elems == 1;
            $!n = self.range.elems;
            die "C0 has incorrect size: {@!C0.elems} != $!n"
                unless @!C0.elems == $!n;
            die "C1 has incorrect size: {@!C1.elems} != $!n"
                unless @!C1.elems == $!n;
        }

        method calc(@in where .elems == 1) {
            my Numeric $x = self.clip(@in[0], @.domain[0]);
            my @out = (0 ..^ $!n).map: -> \j {
                @!C0[j]  +  ($x ** $!N) * (@!C1[j] - @!C0[j]);
            }
            [(@out Z @.range).map: { self.clip(.[0], .[1]) }];
        }
    }
    method interpreter {
        my Range @domain = @.Domain.map: -> $a, $b { Range.new($a, $b) };
        my Range @range = @.Range.map: -> $a, $b { Range.new($a, $b) };
        Interpreter.new: :@domain, :@range, :@.C0, :@.C1, :$.N;
    }
    #| run the calculator function
    method calc(@in) {
        $.interpreter.calc(@in);
    }
 }
